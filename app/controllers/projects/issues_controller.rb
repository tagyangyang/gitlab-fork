class Projects::IssuesController < Projects::ApplicationController
  include NotesHelper
  include ToggleSubscriptionAction
  include IssuableActions
  include ToggleAwardEmoji
  include IssuableCollections
  include SpammableActions

  prepend_before_action :authenticate_user!, only: [:new]

  before_action :redirect_to_external_issue_tracker, only: [:index, :new]
  before_action :module_enabled
  before_action :issue, only: [:edit, :update, :show, :referenced_merge_requests,
                               :related_branches, :can_create_branch, :create_merge_request]

  # Allow read any issue
  before_action :authorize_read_issue!, only: [:show]

  # Allow write(create) issue
  before_action :authorize_create_issue!, only: [:new, :create]

  # Allow modify issue
  before_action :authorize_update_issue!, only: [:edit, :update]

  # Allow create a new branch and empty WIP merge request from current issue
  before_action :authorize_create_merge_request!, only: [:create_merge_request]

  respond_to :html

  def index
    @collection_type    = "Issue"
    @issues             = issues_collection
    @issues             = @issues.page(params[:page])
    @issuable_meta_data = issuable_meta_data(@issues, @collection_type)

    if @issues.out_of_range? && @issues.total_pages != 0
      return redirect_to url_for(params.merge(page: @issues.total_pages))
    end

    if params[:label_name].present?
      @labels = LabelsFinder.new(current_user, project_id: @project.id, title: params[:label_name]).execute
    end

    @users = []

    if params[:assignee_id].present?
      assignee = User.find_by_id(params[:assignee_id])
      @users.push(assignee) if assignee
    end

    if params[:author_id].present?
      author = User.find_by_id(params[:author_id])
      @users.push(author) if author
    end

    respond_to do |format|
      format.html
      format.atom { render layout: false }
      format.json do
        render json: {
          html: view_to_html_string("projects/issues/_issues"),
          labels: @labels.as_json(methods: :text_color)
        }
      end
    end
  end

  def new
    params[:issue] ||= ActionController::Parameters.new(
      assignee_id: ""
    )
    build_params = issue_params.merge(
      merge_request_to_resolve_discussions_of: params[:merge_request_to_resolve_discussions_of],
      discussion_to_resolve: params[:discussion_to_resolve]
    )
    service = Issues::BuildService.new(project, current_user, build_params)

    @issue = @noteable = service.execute
    @merge_request_to_resolve_discussions_of = service.merge_request_to_resolve_discussions_of
    @discussion_to_resolve = service.discussions_to_resolve.first if params[:discussion_to_resolve]

    respond_with(@issue)
  end

  def edit
    respond_with(@issue)
  end

  def show
    raw_notes = @issue.notes.inc_relations_for_view.fresh

    @notes = Banzai::NoteRenderer.
      render(raw_notes, @project, current_user, @path, @project_wiki, @ref)

    @note     = @project.notes.new(noteable: @issue)
    @noteable = @issue

    preload_max_access_for_authors(@notes, @project)

    respond_to do |format|
      format.html
      format.json do
        render json: IssueSerializer.new.represent(@issue)
      end
    end
  end

  def create
    create_params = issue_params.merge(spammable_params).merge(
      merge_request_to_resolve_discussions_of: params[:merge_request_to_resolve_discussions_of],
      discussion_to_resolve: params[:discussion_to_resolve]
    )

    service = Issues::CreateService.new(project, current_user, create_params)
    @issue = service.execute

    if service.discussions_to_resolve.count(&:resolved?) > 0
      flash[:notice] = if service.discussion_to_resolve_id
                         "Resolved 1 discussion."
                       else
                         "Resolved all discussions."
                       end
    end

    respond_to do |format|
      format.html do
        recaptcha_check_with_fallback { render :new }
      end
      format.js do
        @link = @issue.attachment.url.to_js
      end
    end
  end

  def update
    update_params = issue_params.merge(spammable_params)

    @issue = Issues::UpdateService.new(project, current_user, update_params).execute(issue)

    if params[:move_to_project_id].to_i > 0
      new_project = Project.find(params[:move_to_project_id])
      return render_404 unless issue.can_move?(current_user, new_project)

      move_service = Issues::MoveService.new(project, current_user)
      @issue = move_service.execute(@issue, new_project)
    end

    respond_to do |format|
      format.html do
        recaptcha_check_with_fallback { render :edit }
      end

      format.json do
        if @issue.valid?
          render json: @issue.to_json(methods: [:task_status, :task_status_short],
                                      include: { milestone: {},
                                                 assignee: { only: [:name, :username], methods: [:avatar_url] },
                                                 labels: { methods: :text_color } })
        else
          render json: { errors: @issue.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end

  rescue ActiveRecord::StaleObjectError
    render_conflict_response
  end

  def referenced_merge_requests
    @merge_requests = @issue.referenced_merge_requests(current_user)
    @closed_by_merge_requests = @issue.closed_by_merge_requests(current_user)

    respond_to do |format|
      format.json do
        render json: {
          html: view_to_html_string('projects/issues/_merge_requests')
        }
      end
    end
  end

  def related_branches
    @related_branches = @issue.related_branches(current_user)

    respond_to do |format|
      format.json do
        render json: {
          html: view_to_html_string('projects/issues/_related_branches')
        }
      end
    end
  end

  def can_create_branch
    can_create = current_user &&
      can?(current_user, :push_code, @project) &&
      @issue.can_be_worked_on?(current_user)

    respond_to do |format|
      format.json do
        render json: { can_create_branch: can_create }
      end
    end
  end

  def create_merge_request
    result = MergeRequests::CreateFromIssueService.new(project, current_user, issue_iid: issue.iid).execute

    if result[:status] == :success
      render json: MergeRequestCreateSerializer.new.represent(result[:merge_request])
    else
      render json: result[:messsage], status: :unprocessable_entity
    end
  end

  protected

  def issue
    # The Sortable default scope causes performance issues when used with find_by
    @noteable = @issue ||= @project.issues.where(iid: params[:id]).reorder(nil).take || redirect_old
  end
  alias_method :subscribable_resource, :issue
  alias_method :issuable, :issue
  alias_method :awardable, :issue
  alias_method :spammable, :issue

  def authorize_read_issue!
    return render_404 unless can?(current_user, :read_issue, @issue)
  end

  def authorize_update_issue!
    return render_404 unless can?(current_user, :update_issue, @issue)
  end

  def authorize_admin_issues!
    return render_404 unless can?(current_user, :admin_issue, @project)
  end

  def authorize_create_merge_request!
    return render_404 unless can?(current_user, :push_code, @project) && @issue.can_be_worked_on?(current_user)
  end

  def module_enabled
    return render_404 unless @project.feature_available?(:issues, current_user) && @project.default_issues_tracker?
  end

  def redirect_to_external_issue_tracker
    external = @project.external_issue_tracker

    return unless external

    if action_name == 'new'
      redirect_to external.new_issue_path
    else
      redirect_to external.project_path
    end
  end

  # Since iids are implemented only in 6.1
  # user may navigate to issue page using old global ids.
  #
  # To prevent 404 errors we provide a redirect to correct iids until 7.0 release
  #
  def redirect_old
    issue = @project.issues.find_by(id: params[:id])

    if issue
      redirect_to issue_path(issue)
    else
      raise ActiveRecord::RecordNotFound.new
    end
  end

  def issue_params
    params.require(:issue).permit(
      :title, :assignee_id, :position, :description, :confidential,
      :milestone_id, :due_date, :state_event, :task_num, :lock_version, label_ids: []
    )
  end

  def authenticate_user!
    return if current_user

    notice = "Please sign in to create the new issue."

    store_location_for :user, request.fullpath
    redirect_to new_user_session_path, notice: notice
  end
end
