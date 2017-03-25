require 'spec_helper'

RSpec.describe 'Dashboard Archived Project', feature: true do
  let(:user) { create :user }
  let(:project) { create :project}
  let(:archived_project) { create(:project, :archived) }

  before do
    project.team << [user, :master]
    archived_project.team << [user, :master]

    login_as(user)

    visit dashboard_projects_path
  end

  it 'renders non archived projects' do
    expect(page).to have_link(project.name)
    expect(page).not_to have_link(archived_project.name)
  end

  it 'renders all projects' do
    click_link 'Show archived projects'

    expect(page).to have_link(project.name)
    expect(page).to have_link(archived_project.name)
  end

  it 'searches archived projects', :js do
    click_button 'Last updated'
    click_link 'Show archived projects'

    expect(page).to have_link(project.name)
    expect(page).to have_link(archived_project.name)

    fill_in 'project-filter-form-field', with: archived_project.name

    click_button 'Last updated'
    expect(find_link('Show archived projects')[:href]).to end_with "/dashboard/projects?archived=true&sort=updated_desc&name=#{archived_project.name}"

    find('#project-filter-form-field').native.send_keys :return

    expect(page).not_to have_link(project.name)
    expect(page).to have_link(archived_project.name)

    fill_in 'project-filter-form-field', with: ''
    click_button 'Last updated'
    click_link 'Hide archived projects'

    expect(page).not_to have_link(archived_project.name)
    expect(page).to have_link(project.name)
  end
end
