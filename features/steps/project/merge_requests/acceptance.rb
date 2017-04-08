class Spinach::Features::ProjectMergeRequestsAcceptance < Spinach::FeatureSteps
  include LoginHelpers
  include GitlabRoutingHelper
  include WaitForAjax

  step 'I am on the Merge Request detail page' do
    visit merge_request_path(@merge_request)
  end

  step 'I am on the Merge Request detail with note anchor page' do
    visit merge_request_path(@merge_request, anchor: 'note_123')
  end

  step 'I click on "Remove source branch" option' do
    check('Remove source branch')
  end

  step 'I click on Accept Merge Request' do
    click_button('Accept merge request')
  end

  step 'I should see the Remove Source Branch button' do
    expect(page).to have_link('Remove source branch')

    # Wait for AJAX requests to complete so they don't blow up if they are
    # only handled after `DatabaseCleaner` has already run
    wait_for_ajax
  end

  step 'I should not see the Remove Source Branch button' do
    expect(page).not_to have_link('Remove source branch')

    # Wait for AJAX requests to complete so they don't blow up if they are
    # only handled after `DatabaseCleaner` has already run
    wait_for_ajax
  end

  step 'There is an open Merge Request' do
    @user = create(:user)
    @project = create(:project, :public, :repository)
    @project_member = create(:project_member, :developer, user: @user, project: @project)
    @merge_request = create(:merge_request, :with_diffs, :simple, source_project: @project)
  end

  step 'I am signed in as a developer of the project' do
    sign_in(@user)
  end

  step 'I should see merge request merged' do
    expect(page).to have_content('The changes were merged into')
  end
end
