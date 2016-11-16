module VersionCheckHelper
  def version_status_badge
    if Rails.env.production? && current_application_settings.version_check_enabled
      link_to image_tag(VersionCheck.new.url), "https://gitlab.com/gitlab-org/gitlab-ce/blob/master/CHANGELOG.md", :target => "_blank"
    end
  end
end
