require 'spec_helper'

describe Projects::MergeRequestsController, '(JavaScript fixtures)', type: :controller do
  include JavaScriptFixturesHelpers

  let(:admin) { create(:admin) }
  let(:namespace) { create(:namespace, name: 'frontend-fixtures' )}
  let(:project) { create(:project, namespace: namespace, path: 'merge-requests-project') }
  let(:merge_request) { create(:merge_request, :with_diffs, source_project: project, target_project: project, description: '- [ ] Task List Item') }
  let(:pipeline) do
    create(
      :ci_pipeline,
      project: merge_request.source_project,
      ref: merge_request.source_branch,
      sha: merge_request.diff_head_sha
    )
  end

  render_views

  before(:all) do
    clean_frontend_fixtures('merge_requests/')
  end

  before(:each) do
    sign_in(admin)
  end

  it 'merge_requests/open-merge-request.html.raw' do |example|
    render_merge_request(example.description, create(:merge_request, source_project: project, target_project: project))
  end

  it 'merge_requests/closed-merge-request.html.raw' do |example|
    render_merge_request(example.description, create(:closed_merge_request, source_project: project, target_project: project))
  end

  it 'merge_requests/merge_request_with_task_list.html.raw' do |example|
    create(:ci_build, :pending, pipeline: pipeline)

    render_merge_request(example.description, merge_request)
  end

  private

  def render_merge_request(fixture_file_name, merge_request)
    get :show,
      namespace_id: project.namespace.to_param,
      project_id: project,
      id: merge_request.to_param

    expect(response).to be_success
    store_frontend_fixture(response, fixture_file_name)
  end
end
