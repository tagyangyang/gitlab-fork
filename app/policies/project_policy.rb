class ProjectPolicy < BasePolicy
  def self.crua(name)
    [
      :"create_#{name}",
      :"read_#{name}",
      :"update_#{name}",
      :"admin_#{name}"
    ]
  end

  desc "User is a project owner"
  condition :owner do
    !anonymous? && project.owner == user || (project.group && project.group.has_owner?(user))
  end

  desc "Project has public builds enabled"
  condition(:public_builds, scope: :subject) { project.public_builds? }

  desc "User has guest access"

  # For guest access we use #is_team_member? so we can use
  # project.members, which gets cached in subject scope.
  # This is safe because team_access_level is guaranteed
  # by ProjectAuthorization's validation to be at minimum
  # GUEST
  condition(:guest) { is_team_member? }

  desc "User has reporter access"
  condition(:reporter) { team_access_level >= Gitlab::Access::REPORTER }

  desc "User has developer access"
  condition(:developer) { team_access_level >= Gitlab::Access::DEVELOPER }

  desc "User has master access"
  condition(:master) { team_access_level >= Gitlab::Access::MASTER }

  desc "Project is public"
  condition(:public_project, scope: :subject) { project.public? }

  desc "Project is visible to internal users"
  condition(:internal_access) do
    project.internal? && !user.external?
  end

  desc "User is a member of the group"
  condition(:group_member, scope: :subject) { project_group_member?(user) }

  desc "Project is archived"
  condition(:archived, scope: :subject) { project.archived? }

  condition(:default_issues_tracker, scope: :subject) { project.default_issues_tracker? }

  desc "Container registry is disabled"
  condition(:container_registry_disabled, scope: :subject) do
    !project.container_registry_enabled
  end

  desc "Project has an external wiki"
  condition(:has_external_wiki, scope: :subject) { project.has_external_wiki? }

  desc "Project has request access enabled"
  condition(:request_access_enabled, scope: :subject) { project.request_access_enabled }

  features = %w[
    merge_requests
    issues
    repository
    snippets
    wiki
    builds
  ]

  features.each do |f|
    desc "Project has #{f} disabled"
    condition(:"#{f}_disabled") { !feature_available?(f.to_sym) }
  end

  rule { guest }.enable :guest_access
  rule { reporter }.enable :reporter_access
  rule { developer }.enable :developer_access
  rule { master }.enable :master_access

  rule { owner | admin }.policy do
    enable :guest_access
    enable :reporter_access
    enable :developer_access
    enable :master_access

    enable :change_namespace
    enable :change_visibility_level
    enable :rename_project
    enable :remove_project
    enable :archive_project
    enable :remove_fork_project
    enable :destroy_merge_request
    enable :destroy_issue
    enable :remove_pages
  end

  rule { owner | reporter }.policy do
    enable :build_download_code
    enable :build_read_container_image
  end

  rule { can?(:guest_access) }.policy do
    enable :read_project
    enable :read_board
    enable :read_list
    enable :read_wiki
    enable :read_issue
    enable :read_label
    enable :read_milestone
    enable :read_project_snippet
    enable :read_project_member
    enable :read_note
    enable :create_project
    enable :create_issue
    enable :create_note
    enable :upload_file
    enable :read_cycle_analytics
  end

  rule { public_builds & can?(:guest_access) }.policy do
    enable :read_pipeline
    enable :read_build
  end

  rule { can?(:reporter_access) }.policy do
    enable :download_code
    enable :download_wiki_code
    enable :fork_project
    enable :create_project_snippet
    enable :update_issue
    enable :admin_issue
    enable :admin_label
    enable :admin_list
    enable :read_commit_status
    enable :read_build
    enable :read_container_image
    enable :read_pipeline
    enable :read_environment
    enable :read_deployment
    enable :read_merge_request
  end

  rule { (~anonymous & public_project) | internal_access }.policy do
    enable :public_user_access
  end

  rule { can?(:public_user_access) }.policy do
    enable :guest_access
    enable :request_access
  end

  rule { owner | admin | guest | group_member }.prevent :request_access
  rule { ~request_access_enabled }.prevent :request_access

  rule { can?(:developer_access) }.policy do
    enable :admin_merge_request
    enable :update_merge_request
    enable :create_commit_status
    enable :update_commit_status
    enable :create_build
    enable :update_build
    enable :create_pipeline
    enable :update_pipeline
    enable :create_merge_request
    enable :create_wiki
    enable :push_code
    enable :resolve_note
    enable :create_container_image
    enable :update_container_image
    enable :create_environment
    enable :create_deployment
  end

  rule { can?(:master_access) }.policy do
    enable :push_code_to_protected_branches
    enable :update_project_snippet
    enable :update_environment
    enable :update_deployment
    enable :admin_milestone
    enable :admin_project_snippet
    enable :admin_project_member
    enable :admin_note
    enable :admin_wiki
    enable :admin_project
    enable :admin_commit_status
    enable :admin_build
    enable :admin_container_image
    enable :admin_pipeline
    enable :admin_environment
    enable :admin_deployment
    enable :admin_pages
    enable :read_pages
    enable :update_pages
  end

  rule { can?(:public_user_access) }.policy do
    enable :public_access

    enable :fork_project
    enable :build_download_code
    enable :build_read_container_image
  end

  rule { archived }.policy do
    prevent :create_merge_request
    prevent :push_code
    prevent :push_code_to_protected_branches
    prevent :update_merge_request
    prevent :admin_merge_request
  end

  rule { merge_requests_disabled | repository_disabled }.policy do
    prevent(*crua(:merge_request))
  end

  rule { issues_disabled | merge_requests_disabled }.policy do
    prevent(*crua(:label))
    prevent(*crua(:milestone))
  end

  rule { snippets_disabled }.policy do
    prevent(*crua(:project_snippet))
  end

  rule { wiki_disabled & ~has_external_wiki }.policy do
    prevent(*crua(:wiki))
    prevent(:download_wiki_code)
  end

  rule { builds_disabled | repository_disabled }.policy do
    prevent(*crua(:build))
    prevent(*crua(:pipeline))
    prevent(*crua(:environment))
    prevent(*crua(:deployment))
  end

  rule { repository_disabled }.policy do
    prevent :push_code
    prevent :push_code_to_protected_branches
    prevent :download_code
    prevent :fork_project
    prevent :read_commit_status
  end

  rule { container_registry_disabled }.policy do
    prevent(*crua(:container_image))
  end

  rule { anonymous & ~public_project }.prevent_all
  rule { public_project }.enable(:public_access)

  rule { can?(:public_access) }.policy do
    enable :read_project
    enable :read_board
    enable :read_list
    enable :read_wiki
    enable :read_label
    enable :read_milestone
    enable :read_project_snippet
    enable :read_project_member
    enable :read_merge_request
    enable :read_note
    enable :read_pipeline
    enable :read_commit_status
    enable :read_container_image
    enable :download_code
    enable :download_wiki_code
    enable :read_cycle_analytics

    # NOTE: may be overridden by IssuePolicy
    enable :read_issue
  end

  rule { anonymous & public_builds }.policy do
    enable :read_build
  end

  rule { issues_disabled }.policy do
    prevent :create_issue
    prevent :update_issue
    prevent :admin_issue
  end

  rule { issues_disabled & default_issues_tracker }.policy do
    prevent :read_issue
  end

  private

  def is_team_member?
    return false if @user.nil?

    # when scoping by subject, we want to be greedy
    # and load *all* the members with one query.
    #
    # otherwise we just make a specific query for
    # this particular user.
    case DeclarativePolicy.preferred_scope
    when :subject
      project.team.members.include?(user)
    else
      project.team.member?(user)
    end
  end

  def project_group_member?(user)
    return false if anonymous?

    project.group &&
      (
        project.group.members_with_parents.exists?(user_id: user.id) ||
        project.group.requesters.exists?(user_id: user.id)
      )
  end

  def team_access_level
    return -1 if anonymous?
    @team_access_level ||= project.team.max_member_access(user.id)
  end

  def feature_available?(feature)
    project.feature_available?(feature, user)
  end

  def project
    @subject
  end
end
