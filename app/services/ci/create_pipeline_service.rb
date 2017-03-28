module Ci
  class CreatePipelineService < BaseService
    attr_reader :pipeline

    def execute(ignore_skip_ci: false, save_on_errors: true, trigger_request: nil)
      @pipeline = Ci::Pipeline.new(
        project: project,
        ref: ref,
        sha: sha,
        before_sha: before_sha,
        tag: tag?,
        trigger_requests: Array(trigger_request),
        user: current_user
      )

      unless project.builds_enabled?
        return error('Pipeline is disabled')
      end

      unless trigger_request || can?(current_user, :create_pipeline, project)
        return error('Insufficient permissions to create a new pipeline')
      end

      unless branch? || tag?
        return error('Reference not found')
      end

      unless commit
        return error('Commit not found')
      end

      unless pipeline.config_processor
        unless pipeline.ci_yaml_file
          return error('Missing .gitlab-ci.yml file')
        end
        return error(pipeline.yaml_errors, save: save_on_errors)
      end

      if !ignore_skip_ci && skip_ci?
        pipeline.skip if save_on_errors
        return pipeline
      end

      unless pipeline.config_builds_attributes.present?
        return error('No builds for this pipeline.')
      end

      Ci::Pipeline.transaction do
        update_merge_requests_head_pipeline if pipeline.save

        Ci::CreatePipelineBuildsService
          .new(project, current_user)
          .execute(pipeline)
      end

      pipeline.tap(&:process!)
    end

    private

    def skip_ci?
      return false unless pipeline.git_commit_message
      pipeline.git_commit_message =~ /\[(ci[ _-]skip|skip[ _-]ci)\]/i
    end

    def commit
      @commit ||= project.commit(origin_sha || origin_ref)
    end

    def sha
      commit.try(:id)
    end

    def before_sha
      params[:checkout_sha] || params[:before] || Gitlab::Git::BLANK_SHA
    end

    def origin_sha
      params[:checkout_sha] || params[:after]
    end

    def origin_ref
      params[:ref]
    end

    def branch?
      project.repository.ref_exists?(Gitlab::Git::BRANCH_REF_PREFIX + ref)
    end

    def tag?
      project.repository.ref_exists?(Gitlab::Git::TAG_REF_PREFIX + ref)
    end

    def ref
      Gitlab::Git.ref_name(origin_ref)
    end

    def valid_sha?
      origin_sha && origin_sha != Gitlab::Git::BLANK_SHA
    end

    def update_merge_requests_head_pipeline
      merge_requests = MergeRequest.where(source_branch: @pipeline.ref, source_project: @pipeline.project)

      merge_requests.update_all(head_pipeline_id: @pipeline.id) if merge_requests.any?
    end

    def error(message, save: false)
      pipeline.errors.add(:base, message)
      pipeline.drop if save
      pipeline
    end
  end
end
