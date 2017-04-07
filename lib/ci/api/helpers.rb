module Ci
  module API
    module Helpers
      BUILD_TOKEN_HEADER = "HTTP_BUILD_TOKEN".freeze
      BUILD_TOKEN_PARAM = :token
      UPDATE_RUNNER_EVERY = 10 * 60

      def authenticate_runners!
        forbidden! unless runner_registration_token_valid?
      end

      def authenticate_runner!
        forbidden! unless current_runner
      end

      def authenticate_build!
        build = Ci::Build.find_by_id(params[:id])

        validate_build!(build) do
          forbidden! unless build_token_valid?(build)
        end

        build
      end

      def validate_build!(build)
        not_found! unless build

        yield if block_given?

        forbidden!('Project has been deleted!') unless build.project
        forbidden!('Build has been erased!') if build.erased?
      end

      def runner_registration_token_valid?
        ActiveSupport::SecurityUtils.variable_size_secure_compare(
          params[:token],
          current_application_settings.runners_registration_token)
      end

      def build_token_valid?(build)
        token = (params[BUILD_TOKEN_PARAM] || env[BUILD_TOKEN_HEADER]).to_s

        # We require to also check `runners_token` to maintain compatibility with old version of runners
        token && (build.valid_token?(token) || build.project.valid_runners_token?(token))
      end

      def update_runner_info
        return unless update_runner?

        current_runner.contacted_at = Time.now
        current_runner.assign_attributes(get_runner_version_from_params)
        current_runner.save if current_runner.changed?
      end

      def update_runner?
        # Use a random threshold to prevent beating DB updates.
        # It generates a distribution between [40m, 80m].
        #
        contacted_at_max_age = UPDATE_RUNNER_EVERY + Random.rand(UPDATE_RUNNER_EVERY)

        current_runner.contacted_at.nil? ||
          (Time.now - current_runner.contacted_at) >= contacted_at_max_age
      end

      def build_not_found!
        if headers['User-Agent'].to_s =~ /gitlab-ci-multi-runner \d+\.\d+\.\d+(~beta\.\d+\.g[0-9a-f]+)? /
          no_content!
        else
          not_found!
        end
      end

      def current_runner
        @runner ||= Runner.find_by_token(params[:token].to_s)
      end

      def get_runner_version_from_params
        return unless params["info"].present?
        attributes_for_keys(%w(name version revision platform architecture), params["info"])
      end

      def max_artifacts_size
        current_application_settings.max_artifacts_size.megabytes.to_i
      end
    end
  end
end
