module Files
  class UpdateService < Files::BaseService
    FileChangedError = Class.new(StandardError)

    def commit
      repository.update_file(current_user, @file_path, @file_content,
                             message: @commit_message,
                             branch_name: @branch_name,
                             previous_path: @previous_path,
                             author_email: @author_email,
                             author_name: @author_name,
                             start_project: @start_project,
                             start_branch_name: @start_branch)
    end

    private

    def validate!
      super

      if @file_content.nil?
        raise_error("You must provide content.")
      end

      if file_has_changed?
        raise FileChangedError.new("You are attempting to update a file that has changed since you started editing it.")
      end
    end
  end
end
