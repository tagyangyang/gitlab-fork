require File.expand_path('../boot', __FILE__)

require 'rails/all'

Bundler.require(:default, Rails.env)

module Gitlab
  class Application < Rails::Application
    require_dependency Rails.root.join('lib/gitlab/redis')
    require_dependency Rails.root.join('lib/gitlab/request_context')

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Sidekiq uses eager loading, but directories not in the standard Rails
    # directories must be added to the eager load paths:
    # https://github.com/mperham/sidekiq/wiki/FAQ#why-doesnt-sidekiq-autoload-my-rails-application-code
    # Also, there is no need to add `lib` to autoload_paths since autoloading is
    # configured to check for eager loaded paths:
    # https://github.com/rails/rails/blob/v4.2.6/railties/lib/rails/engine.rb#L687
    # This is a nice reference article on autoloading/eager loading:
    # http://blog.arkency.com/2014/11/dont-forget-about-eager-load-when-extending-autoload
    config.eager_load_paths.push(*%W(#{config.root}/lib
                                     #{config.root}/app/models/ci
                                     #{config.root}/app/models/hooks
                                     #{config.root}/app/models/members
                                     #{config.root}/app/models/project_services
                                     #{config.root}/app/workers/concerns
                                     #{config.root}/app/services/concerns
                                     #{config.root}/app/uploaders/concerns))

    config.generators.templates.push("#{config.root}/generator_templates")

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    config.i18n.enforce_available_locales = false

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    #
    # Parameters filtered:
    # - Password (:password, :password_confirmation)
    # - Private tokens
    # - Two-factor tokens (:otp_attempt)
    # - Repo/Project Import URLs (:import_url)
    # - Build variables (:variables)
    # - GitLab Pages SSL cert/key info (:certificate, :encrypted_key)
    # - Webhook URLs (:hook)
    # - GitLab-shell secret token (:secret_token)
    # - Sentry DSN (:sentry_dsn)
    # - Deploy keys (:key)
    config.filter_parameters += %i(
      authentication_token
      certificate
      encrypted_key
      hook
      import_url
      incoming_email_token
      key
      otp_attempt
      password
      password_confirmation
      private_token
      runners_token
      secret_token
      sentry_dsn
      variables
    )

    # Enable escaping HTML in JSON.
    config.active_support.escape_html_entities_in_json = true

    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    # config.active_record.schema_format = :sql

    # Configure webpack
    config.webpack.config_file = "config/webpack.config.js"
    config.webpack.output_dir  = "public/assets/webpack"
    config.webpack.public_path = "assets/webpack"

    # Webpack dev server configuration is handled in initializers/static_files.rb
    config.webpack.dev_server.enabled = false

    # Enable the asset pipeline
    config.assets.enabled = true
    # Support legacy unicode file named img emojis, `1F939.png`
    config.assets.paths << Gemojione.images_path
    config.assets.paths << "vendor/assets/fonts"
    config.assets.precompile << "*.png"
    config.assets.precompile << "print.css"
    config.assets.precompile << "notify.css"
    config.assets.precompile << "mailers/*.css"
    config.assets.precompile << "katex.css"
    config.assets.precompile << "katex.js"
    config.assets.precompile << "xterm/xterm.css"
    config.assets.precompile << "lib/ace.js"
    config.assets.precompile << "vendor/assets/fonts/*"

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    config.action_view.sanitized_allowed_protocols = %w(smb)

    config.middleware.insert_before Warden::Manager, Rack::Attack

    # Allow access to GitLab API from other domains
    config.middleware.insert_before Warden::Manager, Rack::Cors do
      allow do
        origins Gitlab.config.gitlab.url
        resource '/api/*',
          credentials: true,
          headers: :any,
          methods: :any,
          expose: ['Link', 'X-Total', 'X-Total-Pages', 'X-Per-Page', 'X-Page', 'X-Next-Page', 'X-Prev-Page']
      end

      # Cross-origin requests must not have the session cookie available
      allow do
        origins '*'
        resource '/api/*',
          credentials: false,
          headers: :any,
          methods: :any,
          expose: ['Link', 'X-Total', 'X-Total-Pages', 'X-Per-Page', 'X-Page', 'X-Next-Page', 'X-Prev-Page']
      end
    end

    # Use Redis caching across all environments
    redis_config_hash = Gitlab::Redis.params
    redis_config_hash[:namespace] = Gitlab::Redis::CACHE_NAMESPACE
    redis_config_hash[:expires_in] = 2.weeks # Cache should not grow forever
    if Sidekiq.server? # threaded context
      redis_config_hash[:pool_size] = Sidekiq.options[:concurrency] + 5
      redis_config_hash[:pool_timeout] = 1
    end
    config.cache_store = :redis_store, redis_config_hash

    config.active_record.raise_in_transactional_callbacks = true

    config.active_job.queue_adapter = :sidekiq

    # This is needed for gitlab-shell
    ENV['GITLAB_PATH_OUTSIDE_HOOK'] = ENV['PATH']

    config.generators do |g|
      g.factory_girl false
    end
  end
end
