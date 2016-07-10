module Gitlab
  module DependencyLinker
    class PodspecJsonLinker < JsonLinker
      def self.support?(blob_name)
        blob_name.end_with?('.podspec.json')
      end

      private

      def link_dependencies
        link_json("name", json["name"])
        link_json("license", &method(:license_url))

        link_dependencies_at_key("dependencies")

        subspecs = json["subspecs"]
        if subspecs
          subspecs.each do |subspec|
            link_dependencies_at_key("dependencies", subspec)
          end
        end
      end

      def link_dependencies_at_key(key, root = json)
        dependencies = root[key]
        return unless dependencies

        dependencies.each do |name, _|
          link_regex(/"(?<name>#{Regexp.escape(name)})":\s*\[/)
        end
      end

      def package_url(name)
        package = name.split("/", 2).first
        "https://cocoapods.org/pods/#{package}"
      end
    end
  end
end
