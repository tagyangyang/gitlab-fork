require 'spec_helper'

feature 'Create New Merge Request', feature: true, js: true do
  include WaitForVueResource

  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }

  before do
    project.team << [user, :master]

    login_as user
  end

  it 'selects the source branch sha when a tag with the same name exists' do
    visit namespace_project_merge_requests_path(project.namespace, project)

    click_link 'New Merge Request'
    expect(page).to have_content('Source branch')
    expect(page).to have_content('Target branch')

    first('.js-source-branch').click
    first('.dropdown-source-branch .dropdown-content a', text: 'v1.1.0').click

    expect(page).to have_content "b83d6e3"
  end

  it 'selects the target branch sha when a tag with the same name exists' do
    visit namespace_project_merge_requests_path(project.namespace, project)
    
    click_link 'New Merge Request'

    expect(page).to have_content('Source branch')
    expect(page).to have_content('Target branch')

    first('.js-target-branch').click
    first('.dropdown-target-branch .dropdown-content a', text: 'v1.1.0').click

    expect(page).to have_content "b83d6e3"
  end

  it 'generates a diff for an orphaned branch' do
    visit namespace_project_merge_requests_path(project.namespace, project)

    click_link 'New Merge Request'
    expect(page).to have_content('Source branch')
    expect(page).to have_content('Target branch')

    find('.js-source-branch', match: :first).click
    find('.dropdown-source-branch .dropdown-content a', text: 'orphaned-branch', match: :first).click

    click_button "Compare branches"
    click_link "Changes"

    expect(page).to have_content "README.md"
    expect(page).to have_content "wm.png"

    fill_in "merge_request_title", with: "Orphaned MR test"
    click_button "Submit merge request"

    click_link "Check out branch"

    expect(page).to have_content 'git checkout -b orphaned-branch origin/orphaned-branch'
  end

  context 'when target project cannot be viewed by the current user' do
    it 'does not leak the private project name & namespace' do
      private_project = create(:project, :private)

      visit new_namespace_project_merge_request_path(project.namespace, project, merge_request: { target_project_id: private_project.id })

      expect(page).not_to have_content private_project.path_with_namespace
    end
  end

  it 'populates source branch button' do
    visit new_namespace_project_merge_request_path(project.namespace, project, change_branches: true, merge_request: { target_branch: 'master', source_branch: 'fix' })

    expect(find('.js-source-branch')).to have_content('fix')
  end

  it 'allows to change the diff view' do
    visit new_namespace_project_merge_request_path(project.namespace, project, merge_request: { target_branch: 'master', source_branch: 'fix' })

    click_link 'Changes'

    expect(page).to have_css('a.btn.active', text: 'Inline')
    expect(page).not_to have_css('a.btn.active', text: 'Side-by-side')

    click_link 'Side-by-side'

    within '.merge-request' do
      expect(page).not_to have_css('a.btn.active', text: 'Inline')
      expect(page).to have_css('a.btn.active', text: 'Side-by-side')
    end
  end

  it 'does not allow non-existing branches' do
    visit new_namespace_project_merge_request_path(project.namespace, project, merge_request: { target_branch: 'non-exist-target', source_branch: 'non-exist-source' })

    expect(page).to have_content('The form contains the following errors')
    expect(page).to have_content('Source branch "non-exist-source" does not exist')
    expect(page).to have_content('Target branch "non-exist-target" does not exist')
  end

  context 'when a branch contains commits that both delete and add the same image' do
    it 'renders the diff successfully' do
      visit new_namespace_project_merge_request_path(project.namespace, project, merge_request: { target_branch: 'master', source_branch: 'deleted-image-test' })

      click_link "Changes"

      expect(page).to have_content "6049019_460s.jpg"
    end
  end

  # Isolates a regression (see #24627)
  it 'does not show error messages on initial form' do
    visit new_namespace_project_merge_request_path(project.namespace, project)
    expect(page).not_to have_selector('#error_explanation')
    expect(page).not_to have_content('The form contains the following error')
  end

  context 'when a new merge request has a pipeline' do
    let!(:pipeline) do
      create(:ci_pipeline, sha: project.commit('fix').id,
                           ref: 'fix',
                           project: project)
    end

    it 'shows pipelines for a new merge request' do
      visit new_namespace_project_merge_request_path(
        project.namespace, project,
        merge_request: { target_branch: 'master', source_branch: 'fix' })

      page.within('.merge-request') do
        click_link 'Pipelines'
        wait_for_vue_resource

        expect(page).to have_content "##{pipeline.id}"
      end
    end
  end
end
