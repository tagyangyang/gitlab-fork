module CreatesCommit
  extend ActiveSupport::Concern

  def create_commit(service, success_path:, failure_path:, failure_view: nil, success_notice: nil)
    if can?(current_user, :push_code, @project)
      @edit_project = @project
      @branch_name ||= @ref
    else
      @edit_project = current_user.fork_of(@project)
      @branch_name ||= @edit_project.repository.next_branch('patch')
    end

    @start_branch ||= @ref || @branch_name
    @start_branch = nil unless @project.repository.branch_exists?(@start_branch)

    commit_params = @commit_params.merge(
      start_project: @project,
      start_branch: @start_branch,
      branch_name: @branch_name
    )

    result = service.new(@edit_project, current_user, commit_params).execute

    if result[:status] == :success
      update_flash_notice(success_notice)

      success_path = final_success_path(success_path)

      respond_to do |format|
        format.html { redirect_to success_path }
        format.json { render json: { message: "success", filePath: success_path } }
      end
    else
      flash[:alert] = result[:message]
      failure_path = failure_path.call if failure_path.respond_to?(:call)

      respond_to do |format|
        format.html do
          if failure_view
            render failure_view
          else
            redirect_to failure_path
          end
        end
        format.json { render json: { message: "failed", filePath: failure_path } }
      end
    end
  end

  def authorize_edit_tree!
    return if can_collaborate_with_project?

    access_denied!
  end

  private

  def update_flash_notice(success_notice)
    flash[:notice] = success_notice || "Your changes have been successfully committed."

    if create_merge_request?
      if merge_request_exists?
        flash[:notice] = nil
      else
        target = different_project? ? "project" : "branch"
        flash[:notice] << " You can now submit a merge request to get this change into the original #{target}."
      end
    end
  end

  def final_success_path(success_path)
    if create_merge_request?
      merge_request_exists? ? existing_merge_request_path : new_merge_request_path
    else
      success_path = success_path.call if success_path.respond_to?(:call)

      success_path
    end
  end

  def new_merge_request_path
    new_namespace_project_merge_request_path(
      @edit_project.namespace,
      @edit_project,
      merge_request: {
        source_project_id: @edit_project.id,
        target_project_id: @project.id,
        source_branch: @branch_name,
        target_branch: @start_branch
      }
    )
  end

  def existing_merge_request_path
    namespace_project_merge_request_path(@project.namespace, @project, @merge_request)
  end

  def merge_request_exists?
    return @merge_request if defined?(@merge_request)

    @merge_request = MergeRequestsFinder.new(current_user, project_id: @project.id).execute.opened.
      find_by(source_project_id: @edit_project, source_branch: @branch_name, target_branch: @start_branch)
  end

  def different_project?
    @edit_project != @project
  end

  def create_merge_request?
    # Even if the field is set, if we're checking the same branch
    # as the target branch in the same project,
    # we don't want to create a merge request.
    params[:create_merge_request].present? &&
      (different_project? || @start_branch != @branch_name)
  end
end
