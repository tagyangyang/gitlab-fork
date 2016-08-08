class MattermostService
  class MergeMessage < BaseMessage
    attr_reader :params

    def initialize(params)
      @params = params
    end

    private

    def header
      "#{user_name} #{state} #{merge_request_link} on #{project_link}"
    end

    def state
      params[:object_attributes][:state]
    end

    def merge_request_link
      "[merge request !#{resource_id}](#{resource_url})"
    end
  end
end
