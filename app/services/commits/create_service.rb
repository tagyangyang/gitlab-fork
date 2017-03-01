module Commits
  class CreateService < ::BaseService
    ValidationError = Class.new(StandardError)
    ChangeError = Class.new(StandardError)

    def initialize(*args)
      super

      @start_project = params[:start_project] || @project
      @start_branch = params[:start_branch]
      @branch_name = params[:branch_name]
    end

    def execute
      validate!

      result = commit
      if result
        success(result: result)
      else
        error('Something went wrong. Your changes were not committed')
      end
    rescue Repository::CommitError, Gitlab::Git::Repository::InvalidBlobName, GitHooksService::PreReceiveError,
           ValidationError, ChangeError => ex
      error(ex.message)
    end

    private

    def commit
      raise NotImplementedError
    end

    def different_branch?
      @start_branch != @branch_name || @start_project != @project
    end

    def validate!
      allowed = ::Gitlab::UserAccess.new(current_user, project: project).can_push_to_branch?(@branch_name)

      unless allowed
        raise ValidationError, "You are not allowed to push into this branch"
      end

      unless project.empty_repo?
        unless @start_project.repository.branch_exists?(@start_branch)
          raise ValidationError, 'You can only create or edit files when you are on a branch'
        end

        if different_branch?
          if repository.branch_exists?(@branch_name)
            raise ValidationError, 'Branch with such name already exists. You need to switch to this branch in order to make changes'
          end
        end
      end

      # Create new branch if it different from start_branch
      validate_branch! if different_branch?
    end

    def validate_branch!
      result = ValidateNewBranchService.new(project, current_user).
        execute(@branch_name)

      if result[:status] == :error
        raise ValidationError, "Something went wrong when we tried to create #{@branch_name} for you: #{result[:message]}"
      end
    end
  end
end
