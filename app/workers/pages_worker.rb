class PagesWorker
  include Sidekiq::Worker

  sidekiq_options queue: :pages, retry: false

  def perform(action, *arg)
    send(action, *arg)
  end

  def deploy(job_id)
    job = Ci::Build.find_by(id: job_id)
    result = Projects::UpdatePagesService.new(job.project, job).execute

    if result[:status] == :success
      result = Projects::UpdatePagesConfigurationService.new(job.project).execute
    end

    result
  end

  def remove(namespace_path, project_path)
    full_path = File.join(Settings.pages.path, namespace_path, project_path)
    FileUtils.rm_r(full_path, force: true)
  end
end
