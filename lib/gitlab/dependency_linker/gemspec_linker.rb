module Gitlab
  module DependencyLinker
    class GemspecLinker < GemfileLinker
      def self.support?(blob_name)
        blob_name.end_with?('.gemspec')
      end

      private

      def link_dependencies
        link_method_call(%w[name add_dependency add_runtime_dependency add_development_dependency])
        link_method_call("license", &method(:license_url))
      end
    end
  end
end
