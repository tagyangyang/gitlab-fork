module Gitlab
  module DependencyLinker
    class PodspecLinker < PodfileLinker
      def self.support?(blob_name)
        blob_name.end_with?('.podspec')
      end

      private

      def link_dependencies
        link_method_call(%w[name dependency])

        license_regex = %r{
          license
          \s*
          =
          \s*
          (?:
              # spec.license = 'MIT'
              ['"](?<name>[^'"]+)['"]
            |
              # spec.license = { :type => 'MIT' }
              \{\s*:type\s*=>\s*['"](?<name>[^'"]+)['"]
            |
              # spec.license = { type: 'MIT' }
              \{\s*type:\s*['"](?<name>[^'"]+)['"]
          )
        }x
        link_regex(license_regex, &method(:license_url))
      end
    end
  end
end
