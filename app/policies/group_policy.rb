class GroupPolicy < BasePolicy
  desc "Group is public"
  condition(:public_group, scope: :subject) { @subject.public? }
  condition(:logged_in_viewable) { @user && @subject.internal? && !@user.external? }
  condition(:member) { @user && @subject.users_with_parents.include?(@user) }
  condition(:owner) { admin? || @subject.has_owner?(@user) }
  condition(:master) { owner? || @subject.has_master?(@user) }
  condition(:has_projects) do
    GroupProjectsFinder.new(group: @subject, current_user: @user).execute.any?
  end

  condition(:request_access_enabled, scope: :subject) { @subject.request_access_enabled }

  rule { public_group }      .enable :read_group
  rule { logged_in_viewable }.enable :read_group
  rule { member }            .enable :read_group
  rule { admin }             .enable :read_group
  rule { has_projects }      .enable :read_group

  rule { master }.policy do
    enable :create_projects
    enable :admin_milestones
    enable :admin_label
  end

  rule { owner }.policy do
    enable :admin_group
    enable :admin_namespace
    enable :admin_group_member
    enable :change_visibility_level
  end

  rule { public_group | logged_in_viewable }.enable :view_globally

  rule { request_access_enabled & can?(:view_globally) & ~member }.policy do
    enable :request_access
  end
end
