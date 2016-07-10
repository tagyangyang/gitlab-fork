module Gitlab
  module DependencyLinker
    class GodepsJsonLinker < BaseLinker
      def self.support?(blob_name)
        blob_name == 'Godeps.json'
      end

      private

      def link_dependencies
        link_json("ImportPath")
      end

      def package_url(name)
        if name =~ /\A(?<repo>git(lab|hub)\.com\/[^\/]+\/[^\/]+)\/(?<path>.+)\z/
          "http://#{$~[:repo]}/tree/master/#{$~[:path]}"
        else
          "http://#{name}"
        end
      end
    end
  end
end
