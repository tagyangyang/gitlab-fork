require 'spec_helper'

RSpec.describe 'Dashboard Projects', feature: true, js: true do
  let(:user) { create(:user) }
  let(:project) { create(:project, name: "awesome stuff") }
  let(:other_project) { create(:project) }

  before do
    project.team << [user, :developer]
    login_as user
    visit dashboard_projects_path
  end

  it 'shows the project the user in a member of in the list' do
    visit dashboard_projects_path
    expect(page).to have_content(project.name)
  end

  it 'filters projects' do
    visit dashboard_projects_path

    fill_in 'name', with: project.name
    expect(page).to have_content(project.name)
    expect(page).not_to have_content(other_project.name)
  end

  it 'sorts projects' do
    click_button 'Last updated'
    click_link 'Oldest updated'

    expect(page).to have_current_path('/dashboard/projects?sort=updated_asc')
    expect(page).to have_content(project.name)
    expect(page).not_to have_content(other_project.name)
  end

  it 'sorts filtered projects' do
    visit dashboard_projects_path
    url_encoded_name = { name: project.name }.to_query

    fill_in 'name', with: project.name
    find('.js-projects-list-filter').native.send_keys(:return)

    wait_for_requests_complete

    click_button 'Last updated'
    expect(find_link('Oldest created')[:href]).to end_with("/dashboard/projects?#{url_encoded_name}&sort=created_asc")

    fill_in 'name', with: project.name
    expect(page).to have_content(project.name)
    expect(page).not_to have_content(other_project.name)
    wait_for_ajax

    expect(find_link('Oldest created')[:href]).to end_with("/dashboard/projects?#{url_encoded_name}&sort=created_asc")
  end

  describe "with a pipeline" do
    let(:pipeline) {  create(:ci_pipeline, :success, project: project, sha: project.commit.sha) }

    before do
      pipeline
    end

    it 'shows that the last pipeline passed' do
      visit dashboard_projects_path
      expect(page).to have_xpath("//a[@href='#{pipelines_namespace_project_commit_path(project.namespace, project, project.commit)}']")
    end
  end

  it_behaves_like "an autodiscoverable RSS feed with current_user's private token"
end
