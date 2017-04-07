class GitlabUsagePingWorker
  LEASE_TIMEOUT = 86400

  include Sidekiq::Worker
  include CronjobQueue
  include HTTParty

  def perform
    return unless current_application_settings.usage_ping_enabled

    # Multiple Sidekiq workers could run this. We should only do this at most once a day.
    return unless try_obtain_lease

    begin
      HTTParty.post(url,
                    body: Gitlab::UsageData.to_json(force_refresh: true),
                    headers: { 'Content-type' => 'application/json' }
                   )
    rescue HTTParty::Error => e
      Rails.logger.info "Unable to contact GitLab, Inc.: #{e}"
    end
  end

  def try_obtain_lease
    Gitlab::ExclusiveLease.new('gitlab_usage_ping_worker:ping', timeout: LEASE_TIMEOUT).try_obtain
  end

  def url
    'https://version.gitlab.com/usage_data'
  end
end
