class MattermostService
  class WikiPageMessage < BaseMessage
    attr_reader :params

    def initialize(params)
      @params = params
    end

    private

    def header
      "#{user_name} #{action} a #{wiki_page_link} on #{project_link}"
    end

    def description
      params[:object_attributes][:content]
    end

    def action
      case params[:object_attributes][:action]
      when "create"
        "created"
      when "update"
        "edited"
      end
    end

    def wiki_page_link
      "[wiki page](#{wiki_page_url})"
    end
  end
end
