require 'spec_helper'

feature 'Template type dropdown selector', js: true do 
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    project.team << [user, :master]
    login_as user  
  end
  
  context 'editing a non-matching file' do 
    before do
      create_and_edit_file('.random-file.js')
    end
    
    scenario 'displayed' do
      expect_template_type_selector_display(true)
    end

    scenario 'selects every template type correctly' do
      fill_in_matching_filename('.gitignore')
      expect_all_template_types_to_be_properly_selected
    end

    scenario 'updates toggle value when input matches' do
      fill_in_matching_filename('.gitignore')
      ensure_type_selector_toggle_is_set_correctly('.gitignore')
    end
  end
  
  context 'editing a matching file' do 
    before do
      edit_file('LICENSE')
    end
    
    scenario 'not displayed' do
      expect_template_type_selector_display(false)
    end
    
    scenario 'is displayed when input matches' do
      expect_template_type_selector_display(true)
    end

    scenario 'selects every template type correctly' do
      expect_all_template_types_to_be_properly_selected
    end
  end

  context 'creating a matching file' do
    before do
      visit namespace_project_new_blob_path(project.namespace, project, 'master', file_name: '.gitignore')
    end
    
    scenario 'is displayed' do
      expect_template_type_selector_display(true)
    end
    
    scenario 'toggle is set to the correct value' do
      ensure_type_selector_toggle_is_set_correctly('.gitignore')
    end
    
    scenario 'selects every template type correctly' do
      expect_all_template_types_to_be_properly_selected
    end
  end
  
  context 'creating a file' do 
    before do
      visit namespace_project_new_blob_path(project.namespace, project, project.default_branch)
    end

    scenario 'type selector is shown' do
      expect_template_type_selector_display(true)
    end
    
    scenario 'toggle is set to the proper value' do
      ensure_type_selector_toggle_is_set_correctly('Choose type')
    end

    scenario 'selects every template type correctly' do
      expect_all_template_types_to_be_properly_selected
    end
  end
end

def expect_template_type_selector_display(is_visible)
  count = is_visible ? 1 : 0
  expect(page).to have_css('.js-template-type-selector', count: count)
end

def expect_all_template_types_to_be_properly_selected
  ensure_template_type_can_be_selected('LICENSE', 'Apply a License template')
  ensure_template_type_can_be_selected('Dockerfile', 'Apply a Dockerfile template')
  ensure_template_type_can_be_selected('.gitlab-ci.yml', 'Apply a GitLab CI Yaml template')
  ensure_template_type_can_be_selected('.gitignore', 'Apply a .gitignore template')
end

def ensure_template_type_can_be_selected(template_type, selector_label)
  select_template_type(template_type)
  ensure_template_selector_is_displayed(selector_label)
  ensure_type_selector_toggle_is_set_correctly(template_type)
end

def select_template_type(template_type)
  find('.js-template-type-selector').click
  find('.dropdown-content li', text: template_type).click
end

def ensure_template_selector_is_displayed(content)
  expect(page).to have_content(content)
end

def ensure_type_selector_toggle_is_set_correctly(template_type)
  dropdown_toggle_button = find('.template-type-selector .dropdown-toggle-text')
  expect(dropdown_toggle_button).to have_content(template_type)
end

def edit_file(file_name)
  visit namespace_project_edit_blob_path(project.namespace, project, File.join(project.default_branch, file_name))  
end

def create_and_edit_file(file_name)
  visit namespace_project_new_blob_path(project.namespace, project, 'master', file_name: file_name)
  click_button "Commit Changes"
  edit_file(file_name)
end

def fill_in_matching_filename(file_name)
  fill_in 'file_path', with: file_name
end
