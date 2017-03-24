# we need to test that this will work, and display the right dropdown menus
# we could also test the file input matching here
# We need to test that this is displayed correctly on edit/create pages
require 'spec_helper'

feature 'Template type dropdown selector' do 
  before do
    let(:project) { create(:project) }
    let(:user) { create(:user) }
    
    project.team << [user, :master]
    login_as user
  end
  
  context 'editing a non-matching file' do
    before do 
      let(:commit_params) do
        {
        start_branch: project.default_branch,
        target_branch: project.default_branch,
        commit_message: "Committing First Update",
        file_path: "random-file.js",
        file_content: "First Update",
        last_commit_sha: Gitlab::Git::Commit.last_for_path(project.repository, project.default_branch, "random-file.js").sha
        }
        project.team << [user, :master]
        login_as user
        visit namespace_project_edit_blob_path(project.namespace, project, File.join(project.default_branch, 'random-file.js'))
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

    scenario 'updates toggle value when input matches' do
      ensure_type_selector_toggle_is_set_correctly('my-val')
    end
  end
  
  context 'editing a matching file' do
    before do
    end
    
    scenario 'is displayed' do
      expect_template_type_selector_display(true)
    end
    
    scenario 'toggle is set to the correct value' do
      ensure_type_selector_toggle_is_set_correctly('my-val')
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
      ensure_type_selector_toggle_is_set_correctly('my-val')
    end

    scenario 'selects every template type correctly' do
      expect_all_template_types_to_be_properly_selected
    end
  end
end

def expect_template_type_selector_display
  expect(page).to have_css('.js-template-type-selector')
end

def expect_all_template_types_to_be_properly_selected
    within '.js-template-type-selector' do
      ensure_template_type_can_be_selected('LICENSE', 'Apply a License template')
      ensure_template_type_can_be_selected('Dockerfile', 'Apply a Dockerfile template')
      ensure_template_type_can_be_selected('.gitlab-ci.yml', 'Apply a GitLab CI Yaml template')
      ensure_template_type_can_be_selected('.gitignore', 'Apply a .gitignore template')
    end
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
  expect('.dropdown-toggle-text').to have_content(template_type)
end
