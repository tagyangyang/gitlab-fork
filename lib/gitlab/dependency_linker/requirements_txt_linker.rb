module Gitlab
  module DependencyLinker
    class RequirementsTxtLinker < BaseLinker
      def self.support?(blob_name)
        blob_name.end_with?('requirements.txt')
      end

      private

      def link_dependencies
        link_regex(/(?<name>^(?![a-z+]+:)[^#.-][^ ><=;\[]+)/)
      end

      def package_url(name)
        "https://pypi.python.org/pypi/#{name}"
      end
    end
  end
end
