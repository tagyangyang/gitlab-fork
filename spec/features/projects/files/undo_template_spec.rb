require 'spec_helper'
include WaitForAjax

feature 'Template Undo Button', js: true do 
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    project.team << [user, :master]
    login_as user  
  end
  
  context 'editing a matching file and applying a template', focus: true do 
    before do
      edit_file('LICENSE')
      select_template('.js-license-selector', 'Apache License 2.0')
    end
    
    scenario 'is displayed' do
      ensure_undo_can_happen('http://www.apache.org/licenses/', 'Apply a License template')
    end
  end

  context 'creating a matching file' do
    before do
      create_and_edit_file('LICENSE')
      select_template('.js-license-selector', 'Apache License 2.0')
    end

    scenario 'is displayed' do
      ensure_undo_can_happen('http://www.apache.org/licenses/', 'Apply a License template')
    end
  end
  
  context 'creating a non-matching file' do 
    before do
      visit namespace_project_new_blob_path(project.namespace, project, 'master')
      select_template_type('LICENSE')
      select_template('.js-license-selector', 'Apache License 2.0')
    end

    scenario 'is displayed' do
      ensure_undo_can_happen('http://www.apache.org/licenses/', 'Apply a License template')
    end
  end
end

def ensure_undo_can_happen(template_content, toggle_text)
  ensure_undo_button_present
  ensure_undo_works(template_content)
  ensure_template_selection_toggle_text_is_unset(toggle_text)
end
def select_template_type(template_type)
  find('.js-template-type-selector').click
  find('.dropdown-content li', text: template_type).click
end
def ensure_template_selection_toggle_text_is_unset(neutral_toggle_text)
  expect(page).to have_content(neutral_toggle_text)
end

def ensure_undo_button_present
  expect(page).to have_content('Template applied')
  expect(page).to have_css('.template-selectors-undo-menu .btn-info')
end

def ensure_undo_works(template_content)
  find('.template-selectors-undo-menu .btn-info').click
  expect(page).not_to have_content(template_content)
  expect(find('.template-type-selector .dropdown-toggle-text')).to have_content()
end

def select_template(template_selector_selector, template_name)
  find(template_selector_selector).click
  find('.dropdown-content li', text: template_name).click
  wait_for_ajax
end

def expect_template_type_selector_display(is_visible)
  count = is_visible ? 1 : 0
  expect(page).to have_css('.js-template-type-selector', count: count)
end

def select_template_type(template_type)
  find('.js-template-type-selector').click
  find('.dropdown-content li', text: template_type).click
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
