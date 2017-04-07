class MergeRequestPresenter < Gitlab::View::Presenter::Delegated
  include TreeHelper

  presents :merge_request

  def ci_status
    pipeline = merge_request.head_pipeline

    if pipeline
      status = pipeline.status
      status = "success_with_warnings" if pipeline.success? && pipeline.has_warnings?

      status || "preparing"
    else
      ci_service = merge_request.source_project.try(:ci_service)
      ci_service&.commit_status(merge_request.diff_head_sha, merge_request.source_branch)
    end
  end

  def cancel_merge_when_pipeline_succeeds_path
    if merge_request.can_cancel_merge_when_pipeline_succeeds?(current_user)
      cancel_merge_when_pipeline_succeeds_namespace_project_merge_request_path(
        merge_request.project.namespace,
        merge_request.project,
        merge_request)
    end
  end

  def create_issue_to_resolve_discussions_path
    if can?(current_user, :create_issue, merge_request.project) && merge_request.project.issues_enabled?
      new_namespace_project_issue_path(merge_request.project.namespace,
                                       merge_request.project,
                                       merge_request_for_resolving_discussions_of: merge_request.iid)
    end
  end

  def remove_wip_path
    if merge_request.project.merge_requests_enabled? &&
        can?(current_user, :update_merge_request, merge_request.project)

      remove_wip_namespace_project_merge_request_path(merge_request.project.namespace,
                                                      merge_request.project,
                                                      merge_request)
    end
  end

  def merge_path
    if merge_request.can_be_merged_by?(current_user)
      merge_namespace_project_merge_request_path(merge_request.project.namespace,
                                                 merge_request.project,
                                                 merge_request)
    end
  end

  def revert_in_fork_path
    if user_can_fork_project? && can_be_reverted?
      continue_params = {
        to: mr_path,
        notice: "#{edit_in_new_fork_notice} Try to cherry-pick this commit again.",
        notice_now: edit_in_new_fork_notice_now
      }

      namespace_project_forks_path(merge_request.project.namespace, merge_request.project,
                                   namespace_key: current_user.namespace.id,
                                   continue: continue_params)
    end
  end

  def cherry_pick_in_fork_path
    if user_can_fork_project? && merge_request.can_be_cherry_picked?
      continue_params = {
        to: mr_path,
        notice: "#{edit_in_new_fork_notice} Try to revert this commit again.",
        notice_now: edit_in_new_fork_notice_now
      }

      namespace_project_forks_path(merge_request.project.namespace, merge_request.project,
                                   namespace_key: current_user.namespace.id,
                                   continue: continue_params)
    end
  end

  def can_revert_on_current_merge_request?
    user_can_collaborate_with_project? && can_be_reverted?
  end

  def can_cherry_pick_on_current_merge_request?
    user_can_collaborate_with_project? && merge_request.can_be_cherry_picked?
  end

  private

  def mr_path
    namespace_project_merge_request_path(merge_request.project.namespace,
                                         merge_request.project,
                                         merge_request)
  end

  def can_be_reverted?
    merge_request.can_be_reverted?(current_user)
  end

  def user_can_collaborate_with_project?
    can?(current_user, :push_code, merge_request.project) ||
      (current_user && current_user.already_forked?(merge_request.project))
  end

  def user_can_fork_project?
    can?(current_user, :fork_project, merge_request.project)
  end
end
