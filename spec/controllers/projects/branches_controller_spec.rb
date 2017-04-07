require 'spec_helper'

describe Projects::BranchesController do
  let(:project)   { create(:project, :repository) }
  let(:user)      { create(:user) }
  let(:developer) { create(:user) }

  before do
    project.team << [user, :master]
    project.team << [user, :developer]

    allow(project).to receive(:branches).and_return(['master', 'foo/bar/baz'])
    allow(project).to receive(:tags).and_return(['v1.0.0', 'v2.0.0'])
    controller.instance_variable_set(:@project, project)
  end

  describe "POST create" do
    render_views

    context "on creation of a new branch" do
      before do
        sign_in(user)

        post :create,
          namespace_id: project.namespace,
          project_id: project,
          branch_name: branch,
          ref: ref
      end

      context "valid branch name, valid source" do
        let(:branch) { "merge_branch" }
        let(:ref) { "master" }
        it 'redirects' do
          expect(subject).
            to redirect_to("/#{project.path_with_namespace}/tree/merge_branch")
        end
      end

      context "invalid branch name, valid ref" do
        let(:branch) { "<script>alert('merge');</script>" }
        let(:ref) { "master" }
        it 'redirects' do
          expect(subject).
            to redirect_to("/#{project.path_with_namespace}/tree/alert('merge');")
        end
      end

      context "valid branch name, invalid ref" do
        let(:branch) { "merge_branch" }
        let(:ref) { "<script>alert('ref');</script>" }
        it { is_expected.to render_template('new') }
      end

      context "invalid branch name, invalid ref" do
        let(:branch) { "<script>alert('merge');</script>" }
        let(:ref) { "<script>alert('ref');</script>" }
        it { is_expected.to render_template('new') }
      end

      context "valid branch name with encoded slashes" do
        let(:branch) { "feature%2Ftest" }
        let(:ref) { "<script>alert('ref');</script>" }
        it { is_expected.to render_template('new') }
        it { project.repository.branch_names.include?('feature/test') }
      end
    end

    describe "created from the new branch button on issues" do
      let(:branch) { "1-feature-branch" }
      let(:issue) { create(:issue, project: project) }

      before do
        sign_in(user)
      end

      it 'redirects' do
        post :create,
          namespace_id: project.namespace,
          project_id: project,
          branch_name: branch,
          issue_iid: issue.iid

        expect(subject).
          to redirect_to("/#{project.path_with_namespace}/tree/1-feature-branch")
      end

      it 'posts a system note' do
        expect(SystemNoteService).to receive(:new_issue_branch).with(issue, project, user, "1-feature-branch")

        post :create,
          namespace_id: project.namespace,
          project_id: project,
          branch_name: branch,
          issue_iid: issue.iid
      end

      context 'repository-less project' do
        let(:project) { create :empty_project }

        it 'redirects to newly created branch' do
          result = { status: :success, branch: double(name: branch) }

          expect_any_instance_of(CreateBranchService).to receive(:execute).and_return(result)
          expect(SystemNoteService).to receive(:new_issue_branch).and_return(true)

          post :create,
            namespace_id: project.namespace.to_param,
            project_id: project.to_param,
            branch_name: branch,
            issue_iid: issue.iid

          expect(response).to redirect_to namespace_project_tree_path(project.namespace, project, branch)
        end

        it 'redirects to autodeploy setup page' do
          result = { status: :success, branch: double(name: branch) }

          project.services << build(:kubernetes_service)

          expect_any_instance_of(CreateBranchService).to receive(:execute).and_return(result)
          expect(SystemNoteService).to receive(:new_issue_branch).and_return(true)

          post :create,
            namespace_id: project.namespace.to_param,
            project_id: project.to_param,
            branch_name: branch,
            issue_iid: issue.iid

          expect(response.location).to include(namespace_project_new_blob_path(project.namespace, project, branch))
          expect(response).to have_http_status(302)
        end
      end

      context 'without issue feature access' do
        before do
          project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
          project.project_feature.update!(issues_access_level: ProjectFeature::PRIVATE)
          project.team.truncate
        end

        it "doesn't post a system note" do
          expect(SystemNoteService).not_to receive(:new_issue_branch)

          post :create,
            namespace_id: project.namespace,
            project_id: project,
            branch_name: branch,
            issue_iid: issue.iid
        end
      end
    end
  end

  describe "POST destroy with HTML format" do
    render_views

    before do
      sign_in(user)
    end

    it 'returns 303' do
      post :destroy,
           format: :html,
           id: 'foo/bar/baz',
           namespace_id: project.namespace,
           project_id: project

      expect(response).to have_http_status(303)
    end
  end

  describe "POST destroy" do
    render_views

    before do
      sign_in(user)

      post :destroy,
        format: format,
        id: branch,
        namespace_id: project.namespace,
        project_id: project
    end

    context 'as JS' do
      let(:branch) { "feature" }
      let(:format) { :js }

      context "valid branch name, valid source" do
        let(:branch) { "feature" }

        it { expect(response).to have_http_status(200) }
        it { expect(response.body).to be_blank }
      end

      context "valid branch name with unencoded slashes" do
        let(:branch) { "improve/awesome" }

        it { expect(response).to have_http_status(200) }
        it { expect(response.body).to be_blank }
      end

      context "valid branch name with encoded slashes" do
        let(:branch) { "improve%2Fawesome" }

        it { expect(response).to have_http_status(200) }
        it { expect(response.body).to be_blank }
      end

      context "invalid branch name, valid ref" do
        let(:branch) { "no-branch" }

        it { expect(response).to have_http_status(404) }
        it { expect(response.body).to be_blank }
      end
    end

    context 'as JSON' do
      let(:branch) { "feature" }
      let(:format) { :json }

      context 'valid branch name, valid source' do
        let(:branch) { "feature" }

        it 'returns JSON response with message' do
          expect(json_response).to eql("message" => 'Branch was removed')
        end

        it { expect(response).to have_http_status(200) }
      end

      context 'valid branch name with unencoded slashes' do
        let(:branch) { "improve/awesome" }

        it 'returns JSON response with message' do
          expect(json_response).to eql('message' => 'Branch was removed')
        end

        it { expect(response).to have_http_status(200) }
      end

      context "valid branch name with encoded slashes" do
        let(:branch) { 'improve%2Fawesome' }

        it 'returns JSON response with message' do
          expect(json_response).to eql('message' => 'Branch was removed')
        end

        it { expect(response).to have_http_status(200) }
      end

      context 'invalid branch name, valid ref' do
        let(:branch) { 'no-branch' }

        it 'returns JSON response with message' do
          expect(json_response).to eql('message' => 'No such branch')
        end

        it { expect(response).to have_http_status(404) }
      end
    end

    context 'as HTML' do
      let(:branch) { "feature" }
      let(:format) { :html }

      it 'redirects to branches path' do
        expect(response)
          .to redirect_to(namespace_project_branches_path(project.namespace, project))
      end
    end
  end

  describe "DELETE destroy_all_merged" do
    def destroy_all_merged
      delete :destroy_all_merged,
             namespace_id: project.namespace,
             project_id: project
    end

    context 'when user is allowed to push' do
      before do
        sign_in(user)
      end

      it 'redirects to branches' do
        destroy_all_merged

        expect(response).to redirect_to namespace_project_branches_path(project.namespace, project)
      end

      it 'starts worker to delete merged branches' do
        expect_any_instance_of(DeleteMergedBranchesService).to receive(:async_execute)

        destroy_all_merged
      end
    end

    context 'when user is not allowed to push' do
      before do
        sign_in(developer)
      end

      it 'responds with status 404' do
        destroy_all_merged

        expect(response).to have_http_status(404)
      end
    end
  end

  describe "GET index" do
    render_views

    before do
      sign_in(user)
    end

    context 'when rendering a JSON format' do
      it 'filters branches by name' do
        get :index,
            namespace_id: project.namespace,
            project_id: project,
            format: :json,
            search: 'master'

        parsed_response = JSON.parse(response.body)

        expect(parsed_response.length).to eq 1
        expect(parsed_response.first).to eq 'master'
      end
    end

    context 'show_all = true' do
      it 'returns all the branches name' do
        get :index,
            namespace_id: project.namespace,
            project_id: project,
            format: :json,
            show_all: true

        parsed_response = JSON.parse(response.body)

        expect(parsed_response.length).to eq(project.repository.branches.count)
      end
    end
  end
end
