module Users
  # Service for creating a new user.
  class CreateService < BaseService
    def initialize(current_user, params = {})
      @current_user = current_user
      @params = params.dup
    end

    def build
      raise Gitlab::Access::AccessDeniedError unless can_create_user?

      user = User.new(build_user_params)

      if current_user&.is_admin?
        if params[:reset_password]
          @reset_token = user.generate_reset_token
          params[:force_random_password] = true
        end

        if params[:force_random_password]
          random_password = Devise.friendly_token.first(Devise.password_length.min)
          user.password = user.password_confirmation = random_password
        end
      end

      identity_attrs = params.slice(:extern_uid, :provider)

      if identity_attrs.any?
        user.identities.build(identity_attrs)
      end

      user
    end

    def execute
      user = build

      if user.save
        log_info("User \"#{user.name}\" (#{user.email}) was created")
        notification_service.new_user(user, @reset_token) if @reset_token
        system_hook_service.execute_hooks_for(user, :create)
      end

      user
    end

    private

    def can_create_user?
      (current_user.nil? && current_application_settings.signup_enabled?) || current_user&.is_admin?
    end

    # Allowed params for creating a user (admins only)
    def admin_create_params
      [
        :access_level,
        :admin,
        :avatar,
        :bio,
        :can_create_group,
        :color_scheme_id,
        :email,
        :external,
        :force_random_password,
        :password_automatically_set,
        :hide_no_password,
        :hide_no_ssh_key,
        :key_id,
        :linkedin,
        :name,
        :password,
        :password_expires_at,
        :projects_limit,
        :remember_me,
        :skip_confirmation,
        :skype,
        :theme_id,
        :twitter,
        :username,
        :website_url
      ]
    end

    # Allowed params for user signup
    def signup_params
      [
        :email,
        :email_confirmation,
        :password_automatically_set,
        :name,
        :password,
        :username
      ]
    end

    def build_user_params
      if current_user&.is_admin?
        user_params = params.slice(*admin_create_params)
        user_params[:created_by_id] = current_user&.id

        if params[:reset_password]
          user_params.merge!(force_random_password: true, password_expires_at: nil)
        end
      else
        user_params = params.slice(*signup_params)
        user_params[:skip_confirmation] = !current_application_settings.send_user_confirmation_email
      end

      user_params
    end
  end
end
