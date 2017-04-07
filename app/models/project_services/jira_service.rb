class JiraService < IssueTrackerService
  include Gitlab::Routing.url_helpers

  validates :url, url: true, presence: true, if: :activated?
  validates :project_key, presence: true, if: :activated?

  prop_accessor :username, :password, :url, :project_key,
                :jira_issue_transition_id, :title, :description

  before_update :reset_password

  # This is confusing, but JiraService does not really support these events.
  # The values here are required to display correct options in the service
  # configuration screen.
  def self.supported_events
    %w(commit merge_request)
  end

  # {PROJECT-KEY}-{NUMBER} Examples: JIRA-1, PROJECT-1
  def reference_pattern
    @reference_pattern ||= %r{(?<issue>\b([A-Z][A-Z0-9_]+-)\d+)}
  end

  def initialize_properties
    super do
      self.properties = {
        title: issues_tracker['title'],
        url: issues_tracker['url']
      }
    end
  end

  def reset_password
    # don't reset the password if a new one is provided
    if url_changed? && !password_touched?
      self.password = nil
    end
  end

  def options
    url = URI.parse(self.url)

    {
      username: self.username,
      password: self.password,
      site: URI.join(url, '/').to_s,
      context_path: url.path,
      auth_type: :basic,
      read_timeout: 120,
      use_ssl: url.scheme == 'https'
    }
  end

  def client
    @client ||= JIRA::Client.new(options)
  end

  def jira_project
    @jira_project ||= jira_request { client.Project.find(project_key) }
  end

  def help
    "You need to configure JIRA before enabling this service. For more details
    read the
    [JIRA service documentation](#{help_page_url('user/project/integrations/jira')})."
  end

  def title
    if self.properties && self.properties['title'].present?
      self.properties['title']
    else
      'JIRA'
    end
  end

  def description
    if self.properties && self.properties['description'].present?
      self.properties['description']
    else
      'Jira issue tracker'
    end
  end

  def self.to_param
    'jira'
  end

  def fields
    [
      { type: 'text', name: 'url', title: 'URL', placeholder: 'https://jira.example.com' },
      { type: 'text', name: 'project_key', placeholder: 'Project Key' },
      { type: 'text', name: 'username', placeholder: '' },
      { type: 'password', name: 'password', placeholder: '' },
      { type: 'text', name: 'jira_issue_transition_id', placeholder: '' }
    ]
  end

  # URLs to redirect from Gitlab issues pages to jira issue tracker
  def project_url
    "#{url}/issues/?jql=project=#{project_key}"
  end

  def issues_url
    "#{url}/browse/:id"
  end

  def new_issue_url
    "#{url}/secure/CreateIssue.jspa"
  end

  def execute(push)
    # This method is a no-op, because currently JiraService does not
    # support any events.
  end

  def close_issue(entity, external_issue)
    issue = jira_request { client.Issue.find(external_issue.iid) }

    return if issue.nil? || issue.resolution.present? || !jira_issue_transition_id.present?

    commit_id = if entity.is_a?(Commit)
                  entity.id
                elsif entity.is_a?(MergeRequest)
                  entity.diff_head_sha
                end

    commit_url = build_entity_url(:commit, commit_id)

    # Depending on the JIRA project's workflow, a comment during transition
    # may or may not be allowed. Refresh the issue after transition and check
    # if it is closed, so we don't have one comment for every commit.
    issue = jira_request { client.Issue.find(issue.key) } if transition_issue(issue)
    add_issue_solved_comment(issue, commit_id, commit_url) if issue.resolution
  end

  def create_cross_reference_note(mentioned, noteable, author)
    unless can_cross_reference?(noteable)
      return "Events for #{noteable.model_name.plural.humanize(capitalize: false)} are disabled."
    end

    jira_issue = jira_request { client.Issue.find(mentioned.id) }

    return unless jira_issue.present?

    noteable_id   = noteable.respond_to?(:iid) ? noteable.iid : noteable.id
    noteable_type = noteable_name(noteable)
    entity_url    = build_entity_url(noteable_type, noteable_id)

    data = {
      user: {
        name: author.name,
        url: resource_url(user_path(author)),
      },
      project: {
        name: self.project.path_with_namespace,
        url: resource_url(namespace_project_path(project.namespace, self.project))
      },
      entity: {
        name: noteable_type.humanize.downcase,
        url: entity_url,
        title: noteable.title
      }
    }

    add_comment(data, jira_issue)
  end

  # reason why service cannot be tested
  def disabled_title
    "Please fill in Password and Username."
  end

  def test(_)
    result = test_settings
    { success: result.present?, result: result }
  end

  def can_test?
    username.present? && password.present?
  end

  # JIRA does not need test data.
  # We are requesting the project that belongs to the project key.
  def test_data(user = nil, project = nil)
    nil
  end

  def test_settings
    return unless url.present?
    # Test settings by getting the project
    jira_request { jira_project.present? }
  end

  private

  def can_cross_reference?(noteable)
    case noteable
    when Commit then commit_events
    when MergeRequest then merge_requests_events
    else true
    end
  end

  def transition_issue(issue)
    issue.transitions.build.save(transition: { id: jira_issue_transition_id })
  end

  def add_issue_solved_comment(issue, commit_id, commit_url)
    link_title   = "GitLab: Solved by commit #{commit_id}."
    comment      = "Issue solved with [#{commit_id}|#{commit_url}]."
    link_props   = build_remote_link_props(url: commit_url, title: link_title, resolved: true)
    send_message(issue, comment, link_props)
  end

  def add_comment(data, issue)
    user_name    = data[:user][:name]
    user_url     = data[:user][:url]
    entity_name  = data[:entity][:name]
    entity_url   = data[:entity][:url]
    entity_title = data[:entity][:title]
    project_name = data[:project][:name]

    message      = "[#{user_name}|#{user_url}] mentioned this issue in [a #{entity_name} of #{project_name}|#{entity_url}]:\n'#{entity_title.chomp}'"
    link_title   = "GitLab: Mentioned on #{entity_name} - #{entity_title}"
    link_props   = build_remote_link_props(url: entity_url, title: link_title)

    unless comment_exists?(issue, message)
      send_message(issue, message, link_props)
    end
  end

  def comment_exists?(issue, message)
    comments = jira_request { issue.comments }

    comments.present? && comments.any? { |comment| comment.body.include?(message) }
  end

  def send_message(issue, message, remote_link_props)
    return unless url.present?

    jira_request do
      if issue.comments.build.save!(body: message)
        remote_link = issue.remotelink.build
        remote_link.save!(remote_link_props)
        result_message = "#{self.class.name} SUCCESS: Successfully posted to #{url}."
      end

      Rails.logger.info(result_message)
      result_message
    end
  end

  def build_remote_link_props(url:, title:, resolved: false)
    status = {
      resolved: resolved
    }

    {
      GlobalID: 'GitLab',
      object: {
        url: url,
        title: title,
        status: status,
        icon: { title: 'GitLab', url16x16: 'https://gitlab.com/favicon.ico' }
      }
    }
  end

  def resource_url(resource)
    "#{Settings.gitlab.base_url.chomp("/")}#{resource}"
  end

  def build_entity_url(noteable_type, entity_id)
    polymorphic_url(
      [
        self.project.namespace.becomes(Namespace),
        self.project,
        noteable_type.to_sym
      ],
      id:   entity_id,
      host: Settings.gitlab.base_url
    )
  end

  def noteable_name(noteable)
    name = noteable.model_name.singular

    # ProjectSnippet inherits from Snippet class so it causes
    # routing error building the URL.
    name == "project_snippet" ? "snippet" : name
  end

  # Handle errors when doing JIRA API calls
  def jira_request
    yield

  rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, Errno::ECONNREFUSED, URI::InvalidURIError, JIRA::HTTPError => e
    Rails.logger.info "#{self.class.name} Send message ERROR: #{url} - #{e.message}"
    nil
  end
end
