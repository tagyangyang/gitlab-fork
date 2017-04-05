include SentryHelper

module Gitlab
  module GonHelper
    def add_gon_variables
      gon.api_version            = 'v4'
      gon.default_avatar_url     = URI.join(Gitlab.config.gitlab.url, ActionController::Base.helpers.image_path('no_avatar.png')).to_s
      gon.max_file_size          = current_application_settings.max_attachment_size
      gon.asset_host             = ActionController::Base.asset_host
      gon.relative_url_root      = Gitlab.config.gitlab.relative_url_root
      gon.shortcuts_path         = help_page_path('shortcuts')
      gon.user_color_scheme      = Gitlab::ColorSchemes.for_user(current_user).css_class
      gon.katex_css_url          = ActionController::Base.helpers.asset_path('katex.css')
      gon.katex_js_url           = ActionController::Base.helpers.asset_path('katex.js')
      gon.sentry_dsn             = sentry_dsn_public if sentry_enabled?
      gon.gitlab_url             = Gitlab.config.gitlab.url
      gon.is_production          = Rails.env.production?

      if current_user
        gon.current_user_id = current_user.id
        gon.current_username = current_user.username
        gon.current_user_fullname = current_user.name
      end
    end
  end
end
