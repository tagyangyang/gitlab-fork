module API
  module Helpers
    module RelatedResourcesHelpers
      include GrapeRouteHelpers::NamedRouteMatcher

      @@issues_available = -> (issue, options) do
        available?(:issues, issue.project, options[:current_user])
      end

      @@merge_requests_available = -> (issue, options) do
        available?(:merge_requests, issue.project, options[:current_user])
      end

      # Builds a full URL based on GrapeEntity env options
      def expose_url(entity_options, path = nil)
        env        = entity_options[:env]
        url_scheme = env['rack.url_scheme']
        http_host  = env['HTTP_HOST']
        path_info  = path || env['PATH_INFO']

        URI::HTTP.build(scheme: url_scheme, host: http_host, path: path_info).to_s
      end

      private

      def available?(feature, project, current_user)
        project.feature_available?(feature, current_user)
      end
    end
  end
end
