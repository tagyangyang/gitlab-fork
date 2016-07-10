module Gitlab
  module DependencyLinker
    class CartfileLinker < BaseLinker
      def self.support?(blob_name)
        blob_name.start_with?('Cartfile')
      end

      private

      def link_dependencies
        link_method_call("github", /[^\/"]+\/[^\/"]+/)
      end

      def package_url(name)
        "https://github.com/#{name}"
      end
    end
  end
end
