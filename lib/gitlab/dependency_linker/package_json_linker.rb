module Gitlab
  module DependencyLinker
    class PackageJsonLinker < JsonLinker
      def self.support?(blob_name)
        blob_name == 'package.json'
      end

      private

      def link_dependencies
        link_json("name", json["name"])
        link_json("license", &method(:license_url))

        link_dependencies_at_key("dependencies")
        link_dependencies_at_key("devDependencies")
      end

      def link_dependencies_at_key(key)
        dependencies = json[key]
        return unless dependencies

        dependencies.each do |name, version|
          link_json(name, version, package: :key)
          link_json(name, /[^\/"]+\/[^\/"]+/) do |name|
            "https://github.com/#{name}"
          end
        end
      end

      def package_url(name)
        "https://npmjs.com/package/#{name}"
      end
    end
  end
end
