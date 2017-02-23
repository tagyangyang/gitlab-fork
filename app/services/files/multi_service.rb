module Files
  class MultiService < Files::BaseService
    FileChangedError = Class.new(StandardError)

    ACTIONS = %w[create update delete move].freeze

    def commit
      repository.multi_action(
        user: current_user,
        message: @commit_message,
        branch_name: @branch_name,
        actions: params[:actions],
        author_email: @author_email,
        author_name: @author_name,
        start_project: @start_project,
        start_branch_name: @start_branch
      )
    end

    private

    def validate!
      super

      params[:actions].each_with_index do |action, index|
        if ACTIONS.include?(action[:action].to_s)
          action[:action] = action[:action].to_sym
        else
          raise ValidationError, "Unknown action type `#{action[:action]}`."
        end

        unless action[:file_path].present?
          raise ValidationError, "You must specify a file_path."
        end

        action[:file_path].slice!(0) if action[:file_path] && action[:file_path].start_with?('/')
        action[:previous_path].slice!(0) if action[:previous_path] && action[:previous_path].start_with?('/')

        validate_path!(action[:file_path])
        validate_path!(action[:previous_path]) if action[:previous_path]

        if project.empty_repo? && action[:action] != :create
          raise ValidationError, "No files to #{action[:action]}."
        end

        case action[:action]
        when :create
          validate_create!(action)
        when :update
          validate_update!(action)
        when :delete
          validate_delete!(action)
        when :move
          validate_move!(action, index)
        else
          raise ValidationError, "Unknown action type `#{action[:action]}`."
        end
      end
    end

    def validate_file_exists!(action)
      file_path = action[:file_path]
      file_path = action[:previous_path] if action[:action] == :move

      blob = @start_project.repository.blob_at_branch(@start_branch, file_path)

      unless blob
        raise ValidationError, "File to be #{action[:action]}d `#{file_path}` does not exist."
      end
    end

    def validate_path!(file)
      if file =~ Gitlab::Regex.directory_traversal_regex
        raise ValidationError,
          'Your changes could not be committed, because the file name, `' +
          file +
          '` ' +
          Gitlab::Regex.directory_traversal_regex_message
      end

      unless file =~ Gitlab::Regex.file_path_regex
        raise ValidationError,
          'Your changes could not be committed, because the file name, `' +
          file +
          '` ' +
          Gitlab::Regex.file_path_regex_message
      end
    end

    def validate_create!(action)
      return if @start_project.empty_repo?

      if @start_project.repository.blob_at_branch(@start_branch, action[:file_path])
        raise ValidationError, "Your changes could not be committed because a file with the name `#{action[:file_path]}` already exists."
      end

      if action[:content].nil?
        raise ValidationError, "You must provide content."
      end
    end

    def validate_update(action)
      if action[:content].nil?
        raise ValidationError, "You must provide content."
      end

      if file_has_changed?
        raise FileChangedError.new("You are attempting to update a file `#{action[:file_path]}` that has changed since you started editing it.")
      end
    end

    def validate_update!(action)
      validate_file_exists!(action)
    end

    def validate_delete!(action)
      validate_file_exists!(action)
    end

    def validate_move!(action, index)
      validate_file_exists!(action)

      if action[:previous_path].nil?
        raise ValidationError, "You must supply the original file path when moving file `#{action[:file_path]}`."
      end

      blob = @start_project.repository.blob_at_branch(@start_branch, action[:file_path])

      if blob
        raise ValidationError, "Move destination `#{action[:file_path]}` already exists."
      end

      if action[:content].nil?
        blob = @start_project.repository.blob_at_branch(@start_branch, action[:previous_path])
        blob.load_all_data!(@start_project.repository) if blob.truncated?
        params[:actions][index][:content] = blob.data
      end
    end
  end
end
