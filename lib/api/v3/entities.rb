module API
  module V3
    module Entities
      class ProjectSnippet < Grape::Entity
        expose :id, :title, :file_name
        expose :author, using: ::API::Entities::UserBasic
        expose :updated_at, :created_at
        expose(:expires_at) { |snippet| nil }

        expose :web_url do |snippet, options|
          Gitlab::UrlBuilder.build(snippet)
        end
      end

      class Build < Grape::Entity
        expose :id, :status, :stage, :name, :ref, :tag, :coverage
        expose :created_at, :started_at, :finished_at
        expose :user, with: ::API::Entities::User
        expose :artifacts_file, using: ::API::Entities::JobArtifactFile, if: -> (build, opts) { build.artifacts? }
        expose :commit, with: ::API::Entities::RepoCommit
        expose :runner, with: ::API::Entities::Runner
        expose :pipeline, with: ::API::Entities::PipelineBasic
      end
    end
  end
end
