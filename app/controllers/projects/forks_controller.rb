class Projects::ForksController < Projects::ApplicationController
  include ContinueParams

  # Authorize
  before_action :require_non_empty_project
  before_action :authorize_download_code!
  before_action :authenticate_user!, only: [:new, :create]

  def index
    base_query = project.forks.includes(:creator)

    @forks               = base_query.merge(ProjectsFinder.new(current_user: current_user).execute)
    @total_forks_count   = base_query.size
    @private_forks_count = @total_forks_count - @forks.size
    @public_forks_count  = @total_forks_count - @private_forks_count

    @sort  = params[:sort] || 'id_desc'
    @forks = @forks.search(params[:filter_projects]) if params[:filter_projects].present?
    @forks = @forks.order_by(@sort).page(params[:page])

    respond_to do |format|
      format.html

      format.json do
        render json: {
          html: view_to_html_string("projects/forks/_projects", projects: @forks)
        }
      end
    end
  end

  def new
    @namespaces = current_user.manageable_namespaces
    @namespaces.delete(@project.namespace)
  end

  def create
    namespace = Namespace.find(params[:namespace_key])

    @forked_project = namespace.projects.find_by(path: project.path)
    @forked_project = nil unless @forked_project && @forked_project.forked_from_project == project

    @forked_project ||= ::Projects::ForkService.new(project, current_user, namespace: namespace).execute

    if @forked_project.saved? && @forked_project.forked?
      if @forked_project.import_in_progress?
        redirect_to namespace_project_import_path(@forked_project.namespace, @forked_project, continue: continue_params)
      else
        if continue_params
          redirect_to continue_params[:to], notice: continue_params[:notice]
        else
          redirect_to namespace_project_path(@forked_project.namespace, @forked_project), notice: "The project '#{@forked_project.name}' was successfully forked."
        end
      end
    else
      render :error
    end
  end
end
