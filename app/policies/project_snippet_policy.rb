class ProjectSnippetPolicy < BasePolicy
  desc "Snippet is public"
  condition(:public_snippet, scope: :subject) { @subject.public? }

  condition(:is_author) { @user && @subject.author == @user }

  condition(:team_member) { @subject.project.team.member?(@user) }

  condition(:internal, scope: :subject) { @subject.internal? }

  rule { internal & ~external_user }.enable :read_project_snippet

  rule { public_snippet }.enable :read_project_snippet

  rule { is_author | admin }.policy do
    enable :read_project_snippet
    enable :update_project_snippet
    enable :admin_project_snippet
  end

  rule { team_member }.enable :read_project_snippet
end
