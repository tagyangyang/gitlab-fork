class MoveToProjectFinder
  PAGE_SIZE = 50

  def initialize(user)
    @user = user
  end

  def execute(from_project, search: nil, offset_id: nil)
    projects = @user.authorized_projects
    projects = projects.search(search) if search.present?
    projects = skip_projects_before(projects, offset_id.to_i) if offset_id.present?
    ProjectTeam.preload_max_member_access(projects.map(&:team))
    projects = take_projects(projects)
    projects.delete(from_project)
    projects
  end

  private

  def skip_projects_before(projects, offset_project_id)
    index = projects.index { |project| project.id == offset_project_id }

    index ? projects.drop(index + 1) : projects
  end

  def take_projects(projects)
    projects.lazy.select do |project|
      @user.can?(:admin_issue, project)
    end.take(PAGE_SIZE).to_a
  end
end
