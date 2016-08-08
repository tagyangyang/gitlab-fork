class MattermostService
  class NoteMessage < BaseMessage
    attr_reader :params

    def initialize(params)
      @params = params
    end

    private

    def header
      "#{user_name} left a note on #{resource_link} at #{project_link}"
    end

    def title
      params[:object_attributes][:note]
    end

    def resource_link
      "[#{noteable_type} #{resource_id}](resource_url)"
    end

    def resource_id
      noteable = params[noteable_type]

      # Support for Issue/MR/Commit/Snippet
      if noteable == 'commit'
        Commit.truncate_sha(noteable[:id])
      else
        noteable[:iid] || noteable[:id]
      end
    end

    def noteable_type
      params[:object_attributes][:noteable_type].to_s.underscore
    end
  end
end
