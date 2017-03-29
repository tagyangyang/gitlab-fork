class Projects::DiscussionsController < Projects::ApplicationController
  before_action :module_enabled
  before_action :merge_request
  before_action :discussion, only: [:resolve, :unresolve]
  before_action :authorize_resolve_discussion!, only: [:resolve, :unresolve]

  def index
    commit = Discussions::CommitWithUnresolvedDiscussionsService.new(project, current_user).execute(merge_request)

    return render_404 unless commit

    respond_to do |format|
      format.patch  do
        send_git_patch @project.repository, commit.diff_refs
      end

      format.diff do
        send_git_diff @project.repository, commit.diff_refs
      end
    end
  end

  def resolve
    Discussions::ResolveService.new(project, current_user, merge_request: merge_request).execute(discussion)

    render json: {
      resolved_by: discussion.resolved_by.try(:name),
      discussion_headline_html: view_to_html_string('discussions/_headline', discussion: discussion)
    }
  end

  def unresolve
    discussion.unresolve!

    render json: {
      discussion_headline_html: view_to_html_string('discussions/_headline', discussion: discussion)
    }
  end

  private

  def merge_request
    @merge_request ||= MergeRequestsFinder.new(current_user, project_id: @project.id).find_by!(iid: params[:merge_request_id])
  end

  def discussion
    @discussion ||= @merge_request.find_discussion(params[:id]) || render_404
  end

  def authorize_resolve_discussion!
    access_denied! unless discussion.can_resolve?(current_user)
  end

  def module_enabled
    render_404 unless @project.feature_available?(:merge_requests, current_user)
  end
end
