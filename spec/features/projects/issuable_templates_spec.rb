require 'spec_helper'

feature 'issuable templates', feature: true, js: true do
  include WaitForAjax

  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }

  before do
    project.team << [user, :master]
    login_as user
  end

  context 'user creates an issue using templates' do
    let(:template_content) { 'this is a test "bug" template' }
    let(:longtemplate_content) { %Q(this\n\n\n\n\nis\n\n\n\n\na\n\n\n\n\nbug\n\n\n\n\ntemplate) }
    let(:issue) { create(:issue, author: user, assignee: user, project: project) }
    let(:description_addition) { ' appending to description' }

    background do
      project.repository.create_file(
        user,
        '.gitlab/issue_templates/bug.md',
        template_content,
        message: 'added issue template',
        branch_name: 'master')
      project.repository.create_file(
        user,
        '.gitlab/issue_templates/test.md',
        longtemplate_content,
        message: 'added issue template',
        branch_name: 'master')
      visit edit_namespace_project_issue_path project.namespace, project, issue
      fill_in :'issue[title]', with: 'test issue title'
    end

    scenario 'user selects "bug" template' do
      select_template 'bug'
      wait_for_ajax
      assert_template
      save_changes
    end

    scenario 'user selects "bug" template and then "no template"' do
      select_template 'bug'
      wait_for_ajax
      select_option 'No template'
      assert_template('')
      save_changes('')
    end

    scenario 'user selects "bug" template, edits description and then selects "reset template"' do
      select_template 'bug'
      wait_for_ajax
      find_field('issue_description').send_keys(description_addition)
      assert_template(template_content + description_addition)
      select_option 'Reset template'
      assert_template
      save_changes
    end

    it 'updates height of markdown textarea' do
      start_height = page.evaluate_script('$(".markdown-area").outerHeight()')

      select_template 'test'
      wait_for_ajax

      end_height = page.evaluate_script('$(".markdown-area").outerHeight()')

      expect(end_height).not_to eq(start_height)
    end
  end

  context 'user creates an issue using templates, with a prior description' do
    let(:prior_description) { 'test issue description' }
    let(:template_content) { 'this is a test "bug" template' }
    let(:issue) { create(:issue, author: user, assignee: user, project: project) }

    background do
      project.repository.create_file(
        user,
        '.gitlab/issue_templates/bug.md',
        template_content,
        message: 'added issue template',
        branch_name: 'master')
      visit edit_namespace_project_issue_path project.namespace, project, issue
      fill_in :'issue[title]', with: 'test issue title'
      fill_in :'issue[description]', with: prior_description
    end

    scenario 'user selects "bug" template' do
      select_template 'bug'
      wait_for_ajax
      assert_template("#{template_content}")
      save_changes
    end
  end

  context 'user creates a merge request using templates' do
    let(:template_content) { 'this is a test "feature-proposal" template' }
    let(:merge_request) { create(:merge_request, :with_diffs, source_project: project) }

    background do
      project.repository.create_file(
        user,
        '.gitlab/merge_request_templates/feature-proposal.md',
        template_content,
        message: 'added merge request template',
        branch_name: 'master')
      visit edit_namespace_project_merge_request_path project.namespace, project, merge_request
      fill_in :'merge_request[title]', with: 'test merge request title'
    end

    scenario 'user selects "feature-proposal" template' do
      select_template 'feature-proposal'
      wait_for_ajax
      assert_template
      save_changes
    end
  end

  context 'user creates a merge request from a forked project using templates' do
    let(:template_content) { 'this is a test "feature-proposal" template' }
    let(:fork_user) { create(:user) }
    let(:fork_project) { create(:project, :public) }
    let(:merge_request) { create(:merge_request, :with_diffs, source_project: fork_project, target_project: project) }

    background do
      logout
      project.team << [fork_user, :developer]
      fork_project.team << [fork_user, :master]
      create(:forked_project_link, forked_to_project: fork_project, forked_from_project: project)
      login_as fork_user
      project.repository.create_file(
        fork_user,
        '.gitlab/merge_request_templates/feature-proposal.md',
        template_content,
        message: 'added merge request template',
        branch_name: 'master')
      visit edit_namespace_project_merge_request_path project.namespace, project, merge_request
      fill_in :'merge_request[title]', with: 'test merge request title'
    end

    context 'feature proposal template' do
      context 'template exists in target project' do
        scenario 'user selects template' do
          select_template 'feature-proposal'
          wait_for_ajax
          assert_template
          save_changes
        end
      end
    end
  end

  def assert_template(expected_content = template_content)
    expect(find('textarea')['value']).to eq(expected_content)
  end

  def save_changes(expected_content = template_content)
    click_button "Save changes"
    expect(page).to have_content expected_content
  end

  def select_template(name)
    find('.js-issuable-selector').click

    find('.js-issuable-selector-wrap .dropdown-content a', text: name, match: :first).click
  end

  def select_option(name)
    find('.js-issuable-selector').click

    find('.js-issuable-selector-wrap .dropdown-footer-list a', text: name, match: :first).click
  end
end
