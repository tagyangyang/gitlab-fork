class Projects::PipelinesSettingsController < Projects::ApplicationController
  before_action :authorize_admin_pipeline!

  def show
    redirect_to namespace_project_settings_ci_cd_path(@project.namespace, @project, params: params)
  end

  def update
    if @project.update_attributes(update_params)
      flash[:notice] = "CI/CD Pipelines settings for '#{@project.name}' were successfully updated."
      redirect_to namespace_project_settings_ci_cd_path(@project.namespace, @project)
    else
      render 'show'
    end
  end

  private

  def create_params
    params.require(:pipeline).permit(:ref)
  end

  def update_params
    params.require(:project).permit(
      :runners_token, :builds_enabled, :build_allow_git_fetch, :build_timeout_in_minutes, :build_coverage_regex,
      :public_builds, :auto_cancel_pending_pipelines
    )
  end
end
