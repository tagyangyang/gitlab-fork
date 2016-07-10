module Gitlab
  module DependencyLinker
    class ComposerJsonLinker < PackageJsonLinker
      def self.support?(blob_name)
        blob_name == 'composer.json'
      end

      private

      def link_dependencies
        link_json("name", json["name"])
        link_json("license", &method(:license_url))

        link_dependencies_at_key("require")
        link_dependencies_at_key("require-dev")
      end

      def package_url(name)
        "https://packagist.org/packages/#{name}" if name =~ /\A[^\/]+\/[^\/]+\z/
      end
    end
  end
end
