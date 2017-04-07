require 'spec_helper'

feature 'project owner creates a license file', feature: true, js: true do
  include WaitForAjax

  let(:project_master) { create(:user) }
  let(:project) { create(:project) }
  background do
    project.repository.delete_file(project_master, 'LICENSE',
      message: 'Remove LICENSE', branch_name: 'master')
    project.team << [project_master, :master]
    login_as(project_master)
    visit namespace_project_path(project.namespace, project)
  end

  scenario 'project master creates a license file manually from a template' do
    visit namespace_project_tree_path(project.namespace, project, project.repository.root_ref)
    find('.add-to-tree').click
    click_link 'New file'

    fill_in :file_name, with: 'LICENSE'

    expect(page).to have_selector('.license-selector')

    select_template('MIT License')

    file_content = first('.file-editor')
    expect(file_content).to have_content('MIT License')
    expect(file_content).to have_content("Copyright (c) #{Time.now.year} #{project.namespace.human_name}")

    fill_in :commit_message, with: 'Add a LICENSE file', visible: true
    click_button 'Commit changes'

    expect(current_path).to eq(
      namespace_project_blob_path(project.namespace, project, 'master/LICENSE'))
    expect(page).to have_content('MIT License')
    expect(page).to have_content("Copyright (c) #{Time.now.year} #{project.namespace.human_name}")
  end

  scenario 'project master creates a license file from the "Add license" link' do
    click_link 'Add License'

    expect(page).to have_content('New file')
    expect(current_path).to eq(
      namespace_project_new_blob_path(project.namespace, project, 'master'))
    expect(find('#file_name').value).to eq('LICENSE')
    expect(page).to have_selector('.license-selector')

    select_template('MIT License')

    file_content = first('.file-editor')
    expect(file_content).to have_content('MIT License')
    expect(file_content).to have_content("Copyright (c) #{Time.now.year} #{project.namespace.human_name}")

    fill_in :commit_message, with: 'Add a LICENSE file', visible: true
    click_button 'Commit changes'

    expect(current_path).to eq(
      namespace_project_blob_path(project.namespace, project, 'master/LICENSE'))
    expect(page).to have_content('MIT License')
    expect(page).to have_content("Copyright (c) #{Time.now.year} #{project.namespace.human_name}")
  end

  def select_template(template)
    page.within('.js-license-selector-wrap') do
      click_button 'Apply a license template'
      click_link template
      wait_for_ajax
    end
  end
end
