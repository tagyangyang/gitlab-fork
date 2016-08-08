class MattermostService
  class BuildMessage < BaseMessage
    attr_reader :params

    def initialize(params)
      @params = params

      puts '-' * 40
      puts params
      puts '-' * 40
    end

    private

    def header
      "Build #{state} on #{ref} by #{user_name} at #{project_link}"
    end

    def title
      "[#{ref}](#{ref_link}) #{failed} in #{duration} #{'second'.pluralize(duration)}"
    end

    def description
      if failed?
        "During #{stage} build #{build_name} "
      else

      end
    end

    def humanized_status
      case status
      when 'success'
        'passed'
      else
        status
      end
    end

    def branch_url
      "#{project_url}/commits/#{ref}"
    end

    def branch_link
      "[#{ref}](#{branch_url})"
    end

    def project_link
      "[#{project_name}](#{project_url})"
    end

    def commit_url
      "#{project_url}/commit/#{sha}/builds"
    end

    def commit_link
      "[#{Commit.truncate_sha(sha)}](#{commit_url})"
    end
  end
end
