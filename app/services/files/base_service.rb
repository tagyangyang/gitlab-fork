module Files
  class BaseService < Commits::CreateService
    def initialize(*args)
      super

      @commit_message = params[:commit_message]
      @file_path      = params[:file_path]
      @previous_path  = params[:previous_path]
      @file_content   = if params[:file_content_encoding] == 'base64'
                          Base64.decode64(params[:file_content])
                        else
                          params[:file_content]
                        end
      @last_commit_sha = params[:last_commit_sha]
      @author_email    = params[:author_email]
      @author_name     = params[:author_name]
    end

    private

    def file_has_changed?
      return false unless @last_commit_sha && last_commit

      @last_commit_sha != last_commit.sha
    end

    def last_commit
      @last_commit ||= Gitlab::Git::Commit.
        last_for_path(@start_project.repository, @start_branch, @file_path)
    end
  end
end
