class RepositoryImportWorker
  include Sidekiq::Worker
  include DedicatedSidekiqQueue

  sidekiq_options status_expiration: StuckImportJobsWorker::IMPORT_EXPIRATION

  attr_accessor :project, :current_user

  def perform(project_id)
    @project = Project.find(project_id)
    @current_user = @project.creator

    Gitlab::Metrics.add_event(:import_repository,
                              import_url: @project.import_url,
                              path: @project.path_with_namespace)

    project.update_columns(import_jid: self.jid, import_error: nil)

    result = Projects::ImportService.new(project, current_user).execute

    if result[:status] == :error
      project.mark_import_as_failed(result[:message])
      return
    end

    project.repository.after_import
    project.import_finish
  end
end
