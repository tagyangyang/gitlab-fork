require_relative 'base_presenter'

class ProjectPresenter
  extend Forwardable
  include BasePresenter

  def_delegators :@object, :path, :name, :name_with_namespace
  def_delegators :@object, :namespace, :group, :members, :issues, :merge_requests
  def_delegators :@object, :repository, :pipelines
  def_delegators :@object, :repository_size, :avatar_url
  def_delegators :@object, :visibility_level, :default_branch, :description
  def_delegators :@object, :repo_exists?, :empty_repo?, :default_issues_tracker?
  def_delegators :@object, :archived?, :protected_branch?
  def_delegators :@object, :allowed_to_share_with_group?
  def_delegators :@object, :forked_from_project, :external_wiki
  def_delegators :@object, :forks_count, :star_count, :commit_count
  def_delegators :@object, :http_url_to_repo, :ssh_url_to_repo

  def feature_available?(feature, _ = nil)
    object.feature_available?(:repository, current_user)
  end

  def download_code_possible?
    Ability.allowed?(current_user, :download_code, object)
  end

  def push_code_possible?
    Ability.allowed?(current_user, :push_code, object)
  end

  def fork_possible?
    Ability.allowed?(current_user, :fork_project, object)
  end

  def remove_possible?
    Ability.allowed?(current_user, :remove_project, object)
  end

  def destroy_current_member_possible?
    # We don't use @project.team.find_member because it searches for group members too...
    current_member = object.members.find_by(user_id: current_user.id)

    current_member && Ability.allowed?(current_user, :destroy_project_member, current_member)
  end

  def admin_possible?
    Ability.allowed?(current_user, :admin_project, object)
  end

  def forked_from_project?
    @forked_from_project ||= object.forked_from_project.present?
  end

  def already_forked_by_current_user?
    current_user.already_forked?(object)
  end

  def current_user_fork
    current_user.fork_of(object)
  end

  def starred?
    current_user.starred?(object)
  end

  def license_key
    object.repository.license_key
  end
end
