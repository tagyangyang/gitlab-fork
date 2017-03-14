class Projects::DeploymentsController < Projects::ApplicationController
  before_action :authorize_read_deployment!

  def metrics
    @metrics = deployment.metrics(1.hour) || {}
    render json: @metrics, status: @metrics.any? ? :ok : :no_content
  end

  private

  def deployment
    @deployment ||= environment.deployments.find_by(iid: params[:id])
  end

  def environment
    @environment ||= project.environments.find(params[:environment_id])
  end
end
