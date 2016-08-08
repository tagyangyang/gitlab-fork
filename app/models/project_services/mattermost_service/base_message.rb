class MattermostService
  class BaseMessage
    def initialize(params)
      raise NotImplementedError
    end

    def send(webhook, opts)
      body = opts.merge(text: message)
      HTTParty.post(webhook,  headers: { 'Content-Type' => 'application/json' },
                              body: body.to_json)
    end

    def message
      "**#{header}**\n\n" +
      "#{body}\n\n" +
      footer
    end

    private

    def header
      raise NotImplementedError
    end

    def body
      body = "> ### #{title}\n"

      body << "> #{description.truncate(400)}\n" if description
      body << "\n"
    end
 
    def footer
      "[View on GitLab](#{resource_url})"
    end

    # Override this method unless your resource has a title field
    def title
      params[:object_attributes][:title]
    end

    # Implemention in sub class not required
    def description
      params[:object_attributes][:description]
    end

    def project_link
      "[#{project_name}](#{project_url})"
    end

    def project_name
      params[:project][:path_with_namespace].gsub(/\s/, '')
    end

    def project_url
      params[:project][:web_url]
    end

    def resource_url
      params[:object_attributes][:url]
    end

    def resource_id
      params[:object_attributes][:iid] || params[:object_attributes][:id]
    end

    def user_name
      params[:user][:name]
    end

    def
  end
end
