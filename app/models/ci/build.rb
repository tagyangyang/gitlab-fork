module Ci
  class Build < CommitStatus
    include TokenAuthenticatable
    include AfterCommitQueue
    include Presentable

    belongs_to :runner
    belongs_to :trigger_request
    belongs_to :erased_by, class_name: 'User'

    has_many :deployments, as: :deployable
    has_one :last_deployment, -> { order('deployments.id DESC') }, as: :deployable, class_name: 'Deployment'

    # The "environment" field for builds is a String, and is the unexpanded name
    def persisted_environment
      @persisted_environment ||= Environment.find_by(
        name: expanded_environment_name,
        project: project
      )
    end

    serialize :options
    serialize :yaml_variables, Gitlab::Serializer::Ci::Variables

    delegate :name, to: :project, prefix: true

    validates :coverage, numericality: true, allow_blank: true
    validates :ref, presence: true

    scope :unstarted, ->() { where(runner_id: nil) }
    scope :ignore_failures, ->() { where(allow_failure: false) }
    scope :with_artifacts, ->() { where.not(artifacts_file: [nil, '']) }
    scope :with_artifacts_not_expired, ->() { with_artifacts.where('artifacts_expire_at IS NULL OR artifacts_expire_at > ?', Time.now) }
    scope :with_expired_artifacts, ->() { with_artifacts.where('artifacts_expire_at < ?', Time.now) }
    scope :last_month, ->() { where('created_at > ?', Date.today - 1.month) }
    scope :manual_actions, ->() { where(when: :manual).relevant }

    mount_uploader :artifacts_file, ArtifactUploader
    mount_uploader :artifacts_metadata, ArtifactUploader

    acts_as_taggable

    add_authentication_token_field :token

    before_save :update_artifacts_size, if: :artifacts_file_changed?
    before_save :ensure_token
    before_destroy { unscoped_project }

    after_create :execute_hooks
    after_save :update_project_statistics, if: :artifacts_size_changed?
    after_destroy :update_project_statistics

    class << self
      def first_pending
        pending.unstarted.order('created_at ASC').first
      end

      def retry(build, current_user)
        Ci::RetryBuildService
          .new(build.project, current_user)
          .execute(build)
      end
    end

    state_machine :status do
      event :actionize do
        transition created: :manual
      end

      after_transition any => [:pending] do |build|
        build.run_after_commit do
          BuildQueueWorker.perform_async(id)
        end
      end

      after_transition pending: :running do |build|
        build.run_after_commit do
          BuildHooksWorker.perform_async(id)
        end
      end

      after_transition any => [:success, :failed, :canceled] do |build|
        build.run_after_commit do
          BuildFinishedWorker.perform_async(id)
        end
      end

      after_transition any => [:success] do |build|
        build.run_after_commit do
          BuildSuccessWorker.perform_async(id)
        end
      end
    end

    def detailed_status(current_user)
      Gitlab::Ci::Status::Build::Factory
        .new(self, current_user)
        .fabricate!
    end

    def other_actions
      pipeline.manual_actions.where.not(name: name)
    end

    def playable?
      project.builds_enabled? && has_commands? &&
        action? && manual?
    end

    def action?
      self.when == 'manual'
    end

    def has_commands?
      commands.present?
    end

    def play(current_user)
      # Try to queue a current build
      if self.enqueue
        self.update(user: current_user)
        self
      else
        # Otherwise we need to create a duplicate
        Ci::Build.retry(self, current_user)
      end
    end

    def cancelable?
      active?
    end

    def retryable?
      project.builds_enabled? && has_commands? &&
        (success? || failed? || canceled?)
    end

    def retried?
      !self.pipeline.statuses.latest.include?(self)
    end

    def expanded_environment_name
      ExpandVariables.expand(environment, simple_variables) if environment
    end

    def has_environment?
      environment.present?
    end

    def starts_environment?
      has_environment? && self.environment_action == 'start'
    end

    def stops_environment?
      has_environment? && self.environment_action == 'stop'
    end

    def environment_action
      self.options.fetch(:environment, {}).fetch(:action, 'start') if self.options
    end

    def outdated_deployment?
      success? && !last_deployment.try(:last?)
    end

    def depends_on_builds
      # Get builds of the same type
      latest_builds = self.pipeline.builds.latest

      # Return builds from previous stages
      latest_builds.where('stage_idx < ?', stage_idx)
    end

    def trace_html(**args)
      trace_with_state(**args)[:html] || ''
    end

    def trace_with_state(state: nil, last_lines: nil)
      trace_ansi = trace(last_lines: last_lines)
      if trace_ansi.present?
        Ci::Ansi2html.convert(trace_ansi, state)
      else
        {}
      end
    end

    def timeout
      project.build_timeout
    end

    # A slugified version of the build ref, suitable for inclusion in URLs and
    # domain names. Rules:
    #
    #   * Lowercased
    #   * Anything not matching [a-z0-9-] is replaced with a -
    #   * Maximum length is 63 bytes
    def ref_slug
      slugified = ref.to_s.downcase
      slugified.gsub(/[^a-z0-9]/, '-')[0..62]
    end

    # Variables whose value does not depend on other variables
    def simple_variables
      variables = predefined_variables
      variables += project.predefined_variables
      variables += pipeline.predefined_variables
      variables += runner.predefined_variables if runner
      variables += project.container_registry_variables
      variables += project.deployment_variables if has_environment?
      variables += yaml_variables
      variables += user_variables
      variables += project.secret_variables
      variables += trigger_request.user_variables if trigger_request
      variables
    end

    # All variables, including those dependent on other variables
    def variables
      variables = simple_variables
      variables += persisted_environment.predefined_variables if persisted_environment.present?
      variables
    end

    def merge_request
      merge_requests = MergeRequest.includes(:merge_request_diff)
                                   .where(source_branch: ref,
                                          source_project: pipeline.project)
                                   .reorder(iid: :asc)

      merge_requests.find do |merge_request|
        merge_request.commits_sha.include?(pipeline.sha)
      end
    end

    def repo_url
      auth = "gitlab-ci-token:#{ensure_token!}@"
      project.http_url_to_repo.sub(/^https?:\/\//) do |prefix|
        prefix + auth
      end
    end

    def allow_git_fetch
      project.build_allow_git_fetch
    end

    def update_coverage
      coverage = extract_coverage(trace, coverage_regex)
      update_attributes(coverage: coverage) if coverage.present?
    end

    def extract_coverage(text, regex)
      return unless regex

      matches = text.scan(Regexp.new(regex)).last
      matches = matches.last if matches.is_a?(Array)
      coverage = matches.gsub(/\d+(\.\d+)?/).first

      if coverage.present?
        coverage.to_f
      end
    rescue
      # if bad regex or something goes wrong we dont want to interrupt transition
      # so we just silentrly ignore error for now
    end

    def has_trace_file?
      File.exist?(path_to_trace) || has_old_trace_file?
    end

    def has_trace?
      raw_trace.present?
    end

    def raw_trace(last_lines: nil)
      if File.exist?(trace_file_path)
        Gitlab::Ci::TraceReader.new(trace_file_path).
          read(last_lines: last_lines)
      else
        # backward compatibility
        read_attribute :trace
      end
    end

    ##
    # Deprecated
    #
    # This is a hotfix for CI build data integrity, see #4246
    def has_old_trace_file?
      project.ci_id && File.exist?(old_path_to_trace)
    end

    def trace(last_lines: nil)
      hide_secrets(raw_trace(last_lines: last_lines))
    end

    def trace_length
      if raw_trace
        raw_trace.bytesize
      else
        0
      end
    end

    def trace=(trace)
      recreate_trace_dir
      trace = hide_secrets(trace)
      File.write(path_to_trace, trace)
    end

    def recreate_trace_dir
      unless Dir.exist?(dir_to_trace)
        FileUtils.mkdir_p(dir_to_trace)
      end
    end
    private :recreate_trace_dir

    def append_trace(trace_part, offset)
      recreate_trace_dir
      touch if needs_touch?

      trace_part = hide_secrets(trace_part)

      File.truncate(path_to_trace, offset) if File.exist?(path_to_trace)
      File.open(path_to_trace, 'ab') do |f|
        f.write(trace_part)
      end
    end

    def needs_touch?
      Time.now - updated_at > 15.minutes.to_i
    end

    def trace_file_path
      if has_old_trace_file?
        old_path_to_trace
      else
        path_to_trace
      end
    end

    def dir_to_trace
      File.join(
        Settings.gitlab_ci.builds_path,
        created_at.utc.strftime("%Y_%m"),
        project.id.to_s
      )
    end

    def path_to_trace
      "#{dir_to_trace}/#{id}.log"
    end

    ##
    # Deprecated
    #
    # This is a hotfix for CI build data integrity, see #4246
    # Should be removed in 8.4, after CI files migration has been done.
    #
    def old_dir_to_trace
      File.join(
        Settings.gitlab_ci.builds_path,
        created_at.utc.strftime("%Y_%m"),
        project.ci_id.to_s
      )
    end

    ##
    # Deprecated
    #
    # This is a hotfix for CI build data integrity, see #4246
    # Should be removed in 8.4, after CI files migration has been done.
    #
    def old_path_to_trace
      "#{old_dir_to_trace}/#{id}.log"
    end

    ##
    # Deprecated
    #
    # This contains a hotfix for CI build data integrity, see #4246
    #
    # This method is used by `ArtifactUploader` to create a store_dir.
    # Warning: Uploader uses it after AND before file has been stored.
    #
    # This method returns old path to artifacts only if it already exists.
    #
    def artifacts_path
      # We need the project even if it's soft deleted, because whenever
      # we're really deleting the project, we'll also delete the builds,
      # and in order to delete the builds, we need to know where to find
      # the artifacts, which is depending on the data of the project.
      # We need to retain the project in this case.
      the_project = project || unscoped_project

      old = File.join(created_at.utc.strftime('%Y_%m'),
                      the_project.ci_id.to_s,
                      id.to_s)

      old_store = File.join(ArtifactUploader.artifacts_path, old)
      return old if the_project.ci_id && File.directory?(old_store)

      File.join(
        created_at.utc.strftime('%Y_%m'),
        the_project.id.to_s,
        id.to_s
      )
    end

    def valid_token?(token)
      self.token && ActiveSupport::SecurityUtils.variable_size_secure_compare(token, self.token)
    end

    def has_tags?
      tag_list.any?
    end

    def any_runners_online?
      project.any_runners? { |runner| runner.active? && runner.online? && runner.can_pick?(self) }
    end

    def stuck?
      pending? && !any_runners_online?
    end

    def execute_hooks
      return unless project
      build_data = Gitlab::DataBuilder::Build.build(self)
      project.execute_hooks(build_data.dup, :build_hooks)
      project.execute_services(build_data.dup, :build_hooks)
      PagesService.new(build_data).execute
      project.running_or_pending_build_count(force: true)
    end

    def artifacts?
      !artifacts_expired? && artifacts_file.exists?
    end

    def browsable_artifacts?
      !Gitlab.config.artifacts.object_store.enabled && artifacts_metadata?
    end

    def artifacts_metadata?
      artifacts? && artifacts_metadata.exists?
    end

    def artifacts_metadata_entry(path, **options)
      puts "artifacts metadata_entry for path: #{path} and options: #{options}"

      metadata = Gitlab::Ci::Build::Artifacts::Metadata.new(
        artifacts_metadata.path,
        path,
        **options)

      metadata.to_entry
    end

    def erase_artifacts!
      remove_artifacts_file!
      remove_artifacts_metadata!
      save
    end

    def erase(opts = {})
      return false unless erasable?

      erase_artifacts!
      erase_trace!
      update_erased!(opts[:erased_by])
    end

    def erasable?
      complete? && (artifacts? || has_trace?)
    end

    def erased?
      !self.erased_at.nil?
    end

    def artifacts_expired?
      artifacts_expire_at && artifacts_expire_at < Time.now
    end

    def artifacts_expire_in
      artifacts_expire_at - Time.now if artifacts_expire_at
    end

    def artifacts_expire_in=(value)
      self.artifacts_expire_at =
        if value
          ChronicDuration.parse(value)&.seconds&.from_now
        end
    end

    def has_expiring_artifacts?
      artifacts_expire_at.present?
    end

    def keep_artifacts!
      self.update(artifacts_expire_at: nil)
    end

    def coverage_regex
      super || project.try(:build_coverage_regex)
    end

    def when
      read_attribute(:when) || build_attributes_from_config[:when] || 'on_success'
    end

    def yaml_variables
      read_attribute(:yaml_variables) || build_attributes_from_config[:yaml_variables] || []
    end

    def user_variables
      return [] if user.blank?

      [
        { key: 'GITLAB_USER_ID', value: user.id.to_s, public: true },
        { key: 'GITLAB_USER_EMAIL', value: user.email, public: true }
      ]
    end

    def steps
      [Gitlab::Ci::Build::Step.from_commands(self),
       Gitlab::Ci::Build::Step.from_after_script(self)].compact
    end

    def image
      Gitlab::Ci::Build::Image.from_image(self)
    end

    def services
      Gitlab::Ci::Build::Image.from_services(self)
    end

    def artifacts
      [options[:artifacts]]
    end

    def cache
      [options[:cache]]
    end

    def credentials
      Gitlab::Ci::Build::Credentials::Factory.new(self).create!
    end

    def dependencies
      depended_jobs = depends_on_builds

      return depended_jobs unless options[:dependencies].present?

      depended_jobs.select do |job|
        options[:dependencies].include?(job.name)
      end
    end

    private

    def update_artifacts_size
      self.artifacts_size = if artifacts_file.exists?
                              artifacts_file.size
                            else
                              nil
                            end
    end

    def erase_trace!
      self.trace = nil
    end

    def update_erased!(user = nil)
      self.update(erased_by: user, erased_at: Time.now, artifacts_expire_at: nil)
    end

    def unscoped_project
      @unscoped_project ||= Project.unscoped.find_by(id: project_id)
    end

    CI_REGISTRY_USER = 'gitlab-ci-token'.freeze

    def predefined_variables
      variables = [
        { key: 'CI', value: 'true', public: true },
        { key: 'GITLAB_CI', value: 'true', public: true },
        { key: 'CI_SERVER_NAME', value: 'GitLab', public: true },
        { key: 'CI_SERVER_VERSION', value: Gitlab::VERSION, public: true },
        { key: 'CI_SERVER_REVISION', value: Gitlab::REVISION, public: true },
        { key: 'CI_JOB_ID', value: id.to_s, public: true },
        { key: 'CI_JOB_NAME', value: name, public: true },
        { key: 'CI_JOB_STAGE', value: stage, public: true },
        { key: 'CI_JOB_TOKEN', value: token, public: false },
        { key: 'CI_COMMIT_SHA', value: sha, public: true },
        { key: 'CI_COMMIT_REF_NAME', value: ref, public: true },
        { key: 'CI_COMMIT_REF_SLUG', value: ref_slug, public: true },
        { key: 'CI_REGISTRY_USER', value: CI_REGISTRY_USER, public: true },
        { key: 'CI_REGISTRY_PASSWORD', value: token, public: false },
        { key: 'CI_REPOSITORY_URL', value: repo_url, public: false }
      ]

      variables << { key: "CI_COMMIT_TAG", value: ref, public: true } if tag?
      variables << { key: "CI_PIPELINE_TRIGGERED", value: 'true', public: true } if trigger_request
      variables << { key: "CI_JOB_MANUAL", value: 'true', public: true } if action?
      variables.concat(legacy_variables)
    end

    def legacy_variables
      variables = [
        { key: 'CI_BUILD_ID', value: id.to_s, public: true },
        { key: 'CI_BUILD_TOKEN', value: token, public: false },
        { key: 'CI_BUILD_REF', value: sha, public: true },
        { key: 'CI_BUILD_BEFORE_SHA', value: before_sha, public: true },
        { key: 'CI_BUILD_REF_NAME', value: ref, public: true },
        { key: 'CI_BUILD_REF_SLUG', value: ref_slug, public: true },
        { key: 'CI_BUILD_NAME', value: name, public: true },
        { key: 'CI_BUILD_STAGE', value: stage, public: true }
      ]

      variables << { key: "CI_BUILD_TAG", value: ref, public: true } if tag?
      variables << { key: "CI_BUILD_TRIGGERED", value: 'true', public: true } if trigger_request
      variables << { key: "CI_BUILD_MANUAL", value: 'true', public: true } if action?
      variables
    end

    def build_attributes_from_config
      return {} unless pipeline.config_processor

      pipeline.config_processor.build_attributes(name)
    end

    def hide_secrets(trace)
      return unless trace

      trace = trace.dup
      Ci::MaskSecret.mask!(trace, project.runners_token) if project
      Ci::MaskSecret.mask!(trace, token)
      trace
    end

    def update_project_statistics
      return unless project

      ProjectCacheWorker.perform_async(project_id, [], [:build_artifacts_size])
    end
  end
end
