module Gitlab
  module Template
    class KubernetesConfigTemplate < BaseTemplate
      class << self
        def extension
          '_pod.yaml'
        end

        def categories
          {
            "Default" => ''
          }
        end

        def base_dir
          Rails.root.join('vendor/kubernetes')
        end

        def finder(project = nil)
          Gitlab::Template::Finders::GlobalTemplateFinder.new(self.base_dir, self.extension, self.categories)
        end
      end
    end
  end
end
