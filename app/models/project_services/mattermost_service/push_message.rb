class MattermostService
  class PushMessage < BaseMessage
    attr_reader :params

    def initialize(params)
      @params = params
    end

    private

    def header
      "#{user_name} #{action_text} #{project_link}"
    end

    def action_text
      if new_branch?
        "pushed new #{ref_type} #{branch_link} to"
      elsif removed_branch?
        "removed #{ref_type} #{ref} from"
      else
        "pushed to #{ref_type} #{branch_link} of"
      end
    end

    def title
      "Reviewer please help me here"
    end

    def description
      unless commits.empty?
        commits.first(5).map do |commit|
          "[#{Commit.truncate_sha(commit[:id])}](#{commit[:url]}) #{commit[:message].truncate(50)}"
        end.join("\n")
      end
    end

    def ref_type
      Gitlab::Git.tag_ref?(params[:ref]) ? 'tag' : 'branch'
    end

    def ref
      Gitlab::Git.ref_name(params[:ref])
    end

    def new_branch?
      Gitlab::Git.blank_ref?(before)
    end

    def removed_branch?
      Gitlab::Git.blank_ref?(after)
    end

    def before
      params[:before]
    end

    def after
      params[:after]
    end

    def branch_link
      "[#{ref}](#{resource_url})"
    end

    def resource_url
      "#{project_url}/commits/#{ref}"
    end

    def user_name
      params[:user_name]
    end
  end
end
