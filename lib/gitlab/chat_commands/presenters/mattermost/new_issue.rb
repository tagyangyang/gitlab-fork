module Gitlab::ChatCommands::Presenters::Mattermost
  class NewIssue < Gitlab::ChatCommands::Presenters::Issuable
    def present
      if @resource.errors.any?
        display_errors
      else
        in_channel_response(new_issue)
      end
    end

    def new_issue
      message = [
        "A new issue was opened by #{author.to_reference} on #{project.to_reference}",
        "___",
        "![#{author.name}](#{author.avatar_url}) #{author.name}",
        "**#{@resource.title} · #{resource.to_reference}**",
        "___"
      ].join("\n")

      ephemeral_response(text: message)
    end
  end
end
