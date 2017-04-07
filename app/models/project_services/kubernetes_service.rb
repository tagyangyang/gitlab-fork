class KubernetesService < DeploymentService
  include Gitlab::CurrentSettings
  include Gitlab::Kubernetes
  include ReactiveCaching

  self.reactive_cache_key = ->(service) { [service.class.model_name.singular, service.project_id] }

  # Namespace defaults to the project path, but can be overridden in case that
  # is an invalid or inappropriate name
  prop_accessor :namespace

  #  Access to kubernetes is directly through the API
  prop_accessor :api_url

  # Bearer authentication
  # TODO:  user/password auth, client certificates
  prop_accessor :token

  # Provide a custom CA bundle for self-signed deployments
  prop_accessor :ca_pem

  with_options presence: true, if: :activated? do
    validates :api_url, url: true
    validates :token
  end

  validates :namespace,
    allow_blank: true,
    length: 1..63,
    if: :activated?,
    format: {
      with: Gitlab::Regex.kubernetes_namespace_regex,
      message: Gitlab::Regex.kubernetes_namespace_regex_message
    }

  after_save :clear_reactive_cache!

  def initialize_properties
    self.properties = {} if properties.nil?
  end

  def title
    'Kubernetes'
  end

  def description
    'Kubernetes / Openshift integration'
  end

  def help
    'To enable terminal access to Kubernetes environments, label your ' \
    'deployments with `app=$CI_ENVIRONMENT_SLUG`'
  end

  def self.to_param
    'kubernetes'
  end

  def fields
    [
        { type: 'text',
          name: 'namespace',
          title: 'Kubernetes namespace',
          placeholder: namespace_placeholder },
        { type: 'text',
          name: 'api_url',
          title: 'API URL',
          placeholder: 'Kubernetes API URL, like https://kube.example.com/' },
        { type: 'text',
          name: 'token',
          title: 'Service token',
          placeholder: 'Service token' },
        { type: 'textarea',
          name: 'ca_pem',
          title: 'Custom CA bundle',
          placeholder: 'Certificate Authority bundle (PEM format)' },
    ]
  end

  # Check we can connect to the Kubernetes API
  def test(*args)
    kubeclient = build_kubeclient!

    kubeclient.discover
    { success: kubeclient.discovered, result: "Checked API discovery endpoint" }
  rescue => err
    { success: false, result: err }
  end

  def predefined_variables
    variables = [
      { key: 'KUBE_URL', value: api_url, public: true },
      { key: 'KUBE_TOKEN', value: token, public: false },
      { key: 'KUBE_NAMESPACE', value: namespace_variable, public: true }
    ]

    if ca_pem.present?
      variables << { key: 'KUBE_CA_PEM', value: ca_pem, public: true }
      variables << { key: 'KUBE_CA_PEM_FILE', value: ca_pem, public: true, file: true }
    end

    variables
  end

  # Constructs a list of terminals from the reactive cache
  #
  # Returns nil if the cache is empty, in which case you should try again a
  # short time later
  def terminals(environment)
    with_reactive_cache do |data|
      pods = data.fetch(:pods, nil)
      filter_pods(pods, app: environment.slug).
        flat_map { |pod| terminals_for_pod(api_url, namespace, pod) }.
        each { |terminal| add_terminal_auth(terminal, terminal_auth) }
    end
  end

  # Caches all pods in the namespace so other calls don't need to block on
  # network access.
  def calculate_reactive_cache
    return unless active? && project && !project.pending_delete?

    kubeclient = build_kubeclient!

    # Store as hashes, rather than as third-party types
    pods = begin
      kubeclient.get_pods(namespace: namespace).as_json
    rescue KubeException => err
      raise err unless err.error_code == 404
      []
    end

    # We may want to cache extra things in the future
    { pods: pods }
  end

  TEMPLATE_PLACEHOLDER = 'Kubernetes namespace'.freeze

  private

  def namespace_placeholder
    default_namespace || TEMPLATE_PLACEHOLDER
  end

  def namespace_variable
    if namespace.present?
      namespace
    else
      default_namespace
    end
  end

  def default_namespace
    "#{project.path}-#{project.id}" if project.present?
  end

  def build_kubeclient!(api_path: 'api', api_version: 'v1')
    raise "Incomplete settings" unless api_url && namespace && token

    ::Kubeclient::Client.new(
      join_api_url(api_path),
      api_version,
      auth_options: kubeclient_auth_options,
      ssl_options: kubeclient_ssl_options,
      http_proxy_uri: ENV['http_proxy']
    )
  end

  def kubeclient_ssl_options
    opts = { verify_ssl: OpenSSL::SSL::VERIFY_PEER }

    if ca_pem.present?
      opts[:cert_store] = OpenSSL::X509::Store.new
      opts[:cert_store].add_cert(OpenSSL::X509::Certificate.new(ca_pem))
    end

    opts
  end

  def kubeclient_auth_options
    { bearer_token: token }
  end

  def join_api_url(*parts)
    url = URI.parse(api_url)
    prefix = url.path.sub(%r{/+\z}, '')

    url.path = [prefix, *parts].join("/")

    url.to_s
  end

  def terminal_auth
    {
      token: token,
      ca_pem: ca_pem,
      max_session_time: current_application_settings.terminal_max_session_time
    }
  end
end
