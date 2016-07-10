module Gitlab
  module DependencyLinker
    class PodfileLinker < BaseLinker
      def self.support?(blob_name)
        blob_name == 'Podfile'
      end

      private

      def link_dependencies
        link_method_call("pod")
      end

      def package_url(name)
        package = name.split("/", 2).first
        "https://cocoapods.org/pods/#{package}"
      end
    end
  end
end
