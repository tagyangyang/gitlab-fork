class MattermostService
  class IssueMessage < BaseMessage
    attr_reader :params

    def initialize(params)
      @params = params
    end

    private

    def header
      "#{user_name} #{action} #{issue_link} on #{project_link}"
    end

    def action
      if params[:object_attributes][:action] == 'open'
        'opened'
      else
        'closed'
      end
    end

    def issue_link
      "[issue ##{resource_id}](#{resource_url})"
    end
  end
end
