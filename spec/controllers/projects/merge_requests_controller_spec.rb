require 'spec_helper'

describe Projects::MergeRequestsController do
  include ApiHelpers

  let(:project) { create(:project) }
  let(:user)    { create(:user) }
  let(:merge_request) { create(:merge_request_with_diffs, target_project: project, source_project: project) }
  let(:merge_request_with_conflicts) do
    create(:merge_request, source_branch: 'conflict-resolvable', target_branch: 'conflict-start', source_project: project) do |mr|
      mr.mark_as_unmergeable
    end
  end

  before do
    sign_in(user)
    project.team << [user, :master]
  end

  describe 'GET new' do
    context 'merge request that removes a submodule' do
      render_views

      let(:fork_project) { create(:forked_project_with_submodules) }
      before { fork_project.team << [user, :master] }

      context 'when rendering HTML response' do
        it 'renders new merge request widget template' do
          submit_new_merge_request

          expect(response).to be_success
        end
      end

      context 'when rendering JSON response' do
        before do
          create(:ci_pipeline, sha: fork_project.commit('remove-submodule').id,
                               ref: 'remove-submodule',
                               project: fork_project)
        end

        it 'renders JSON including serialized pipelines' do
          submit_new_merge_request(format: :json)

          expect(response).to be_ok
          expect(json_response).to have_key 'pipelines'
          expect(json_response['pipelines']).not_to be_empty
        end
      end
    end

    def submit_new_merge_request(format: :html)
      get :new,
          namespace_id: fork_project.namespace.to_param,
          project_id: fork_project,
          merge_request: {
            source_branch: 'remove-submodule',
            target_branch: 'master'
          },
          format: format
    end
  end

  shared_examples "loads labels" do |action|
    it "loads labels into the @labels variable" do
      get action,
          namespace_id: project.namespace.to_param,
          project_id: project,
          id: merge_request.iid,
          format: 'html'
      expect(assigns(:labels)).not_to be_nil
    end
  end

  describe "GET show" do
    def go(extra_params = {})
      params = {
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: merge_request.iid
      }

      get :show, params.merge(extra_params)
    end

    it_behaves_like "loads labels", :show

    describe 'as html' do
      it "renders merge request page" do
        go(format: :html)

        expect(response).to be_success
      end
    end

    describe 'as json' do
      it 'renders the merge request in the json format' do
        go(format: :json)

        expect(json_response['iid']).to eq(merge_request.iid)
      end
    end

    describe "as diff" do
      it "triggers workhorse to serve the request" do
        go(format: :diff)

        expect(response.headers[Gitlab::Workhorse::SEND_DATA_HEADER]).to start_with("git-diff:")
      end
    end

    describe "as patch" do
      it 'triggers workhorse to serve the request' do
        go(format: :patch)

        expect(response.headers[Gitlab::Workhorse::SEND_DATA_HEADER]).to start_with("git-format-patch:")
      end
    end
  end

  describe 'GET index' do
    let!(:merge_request) { create(:merge_request_with_diffs, target_project: project, source_project: project) }

    def get_merge_requests(page = nil)
      get :index,
          namespace_id: project.namespace.to_param,
          project_id: project,
          state: 'opened', page: page.to_param
    end

    it_behaves_like "issuables list meta-data", :merge_request

    context 'when page param' do
      let(:last_page) { project.merge_requests.page().total_pages }
      let!(:merge_request) { create(:merge_request_with_diffs, target_project: project, source_project: project) }

      it 'redirects to last_page if page number is larger than number of pages' do
        get_merge_requests(last_page + 1)

        expect(response).to redirect_to(namespace_project_merge_requests_path(page: last_page, state: controller.params[:state], scope: controller.params[:scope]))
      end

      it 'redirects to specified page' do
        get_merge_requests(last_page)

        expect(assigns(:merge_requests).current_page).to eq(last_page)
        expect(response).to have_http_status(200)
      end

      it 'does not redirect to external sites when provided a host field' do
        external_host = "www.example.com"
        get :index,
          namespace_id: project.namespace.to_param,
          project_id: project,
          state: 'opened',
          page: (last_page + 1).to_param,
          host: external_host

        expect(response).to redirect_to(namespace_project_merge_requests_path(page: last_page, state: controller.params[:state], scope: controller.params[:scope]))
      end
    end

    context 'when filtering by opened state' do
      context 'with opened merge requests' do
        it 'lists those merge requests' do
          get_merge_requests

          expect(assigns(:merge_requests)).to include(merge_request)
        end
      end

      context 'with reopened merge requests' do
        before do
          merge_request.close!
          merge_request.reopen!
        end

        it 'lists those merge requests' do
          get_merge_requests

          expect(assigns(:merge_requests)).to include(merge_request)
        end
      end
    end
  end

  describe 'PUT update' do
    context 'changing the assignee' do
      it 'limits the attributes exposed on the assignee' do
        assignee = create(:user)
        project.add_developer(assignee)

        put :update,
          namespace_id: project.namespace.to_param,
          project_id: project,
          id: merge_request.iid,
          merge_request: { assignee_id: assignee.id },
          format: :json
        body = JSON.parse(response.body)

        expect(body['assignee'].keys)
          .to match_array(%w(name username avatar_url))
      end
    end

    context 'there is no source project' do
      let(:project)       { create(:project) }
      let(:fork_project)  { create(:forked_project_with_submodules) }
      let(:merge_request) { create(:merge_request, source_project: fork_project, source_branch: 'add-submodule-version-bump', target_branch: 'master', target_project: project) }

      before do
        fork_project.build_forked_project_link(forked_to_project_id: fork_project.id, forked_from_project_id: project.id)
        fork_project.save
        merge_request.reload
        fork_project.destroy
      end

      it 'closes MR without errors' do
        post :update,
            namespace_id: project.namespace,
            project_id: project,
            id: merge_request.iid,
            merge_request: {
              state_event: 'close'
            }

        expect(response).to redirect_to([merge_request.target_project.namespace.becomes(Namespace), merge_request.target_project, merge_request])
        expect(merge_request.reload.closed?).to be_truthy
      end

      it 'allows editing of a closed merge request' do
        merge_request.close!

        put :update,
            namespace_id: project.namespace,
            project_id: project,
            id: merge_request.iid,
            merge_request: {
              title: 'New title'
            }

        expect(response).to redirect_to([merge_request.target_project.namespace.becomes(Namespace), merge_request.target_project, merge_request])
        expect(merge_request.reload.title).to eq 'New title'
      end

      it 'does not allow to update target branch closed merge request' do
        merge_request.close!

        put :update,
            namespace_id: project.namespace,
            project_id: project,
            id: merge_request.iid,
            merge_request: {
              target_branch: 'new_branch'
            }

        expect { merge_request.reload.target_branch }.not_to change { merge_request.target_branch }
      end

      it_behaves_like 'update invalid issuable', MergeRequest
    end
  end

  describe 'POST merge' do
    let(:base_params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        id: merge_request.iid,
        format: format
      }
    end

    context 'as JSON' do
      let(:format) { 'json' }

      context 'when the user does not have access' do
        before do
          project.team.truncate
          project.team << [user, :reporter]
          xhr :post, :merge, base_params
        end

        it 'returns access denied' do
          expect(response).to have_http_status(401)
        end
      end

      context 'when the merge request is not mergeable' do
        before do
          merge_request.update_attributes(title: "WIP: #{merge_request.title}")

          post :merge, base_params
        end

        it 'returns :failed' do
          expect(json_response).to eq('status' => 'failed')
        end
      end

      context 'when the sha parameter does not match the source SHA' do
        before { post :merge, base_params.merge(sha: 'foo') }

        it 'returns :sha_mismatch' do
          expect(json_response).to eq('status' => 'sha_mismatch')
        end
      end

      context 'when the sha parameter matches the source SHA' do
        def merge_with_sha
          post :merge, base_params.merge(sha: merge_request.diff_head_sha)
        end

        it 'returns :success' do
          merge_with_sha

          expect(json_response).to eq('status' => 'success')
        end

        it 'starts the merge immediately' do
          expect(MergeWorker).to receive(:perform_async).with(merge_request.id, anything, anything)

          merge_with_sha
        end

        context 'when the pipeline succeeds is passed' do
          def merge_when_pipeline_succeeds
            post :merge, base_params.merge(sha: merge_request.diff_head_sha, merge_when_pipeline_succeeds: '1')
          end

          before do
            create(:ci_empty_pipeline, project: project, sha: merge_request.diff_head_sha, ref: merge_request.source_branch)
          end

          it 'returns :merge_when_pipeline_succeeds' do
            merge_when_pipeline_succeeds

            expect(json_response).to eq('status' => 'merge_when_pipeline_succeeds')
          end

          it 'sets the MR to merge when the pipeline succeeds' do
            service = double(:merge_when_pipeline_succeeds_service)

            expect(MergeRequests::MergeWhenPipelineSucceedsService)
              .to receive(:new).with(project, anything, anything)
              .and_return(service)
            expect(service).to receive(:execute).with(merge_request)

            merge_when_pipeline_succeeds
          end

          context 'when project.only_allow_merge_if_pipeline_succeeds? is true' do
            before do
              project.update_column(:only_allow_merge_if_pipeline_succeeds, true)
            end

            it 'returns :merge_when_pipeline_succeeds' do
              merge_when_pipeline_succeeds

              expect(json_response).to eq('status' => 'merge_when_pipeline_succeeds')
            end
          end
        end

        describe 'only_allow_merge_if_all_discussions_are_resolved? setting' do
          let(:merge_request) { create(:merge_request_with_diff_notes, source_project: project, author: user) }

          context 'when enabled' do
            before do
              project.update_column(:only_allow_merge_if_all_discussions_are_resolved, true)
            end

            context 'with unresolved discussion' do
              before do
                expect(merge_request).not_to be_discussions_resolved
              end

              it 'returns :failed' do
                merge_with_sha

                expect(json_response).to eq('status' => 'failed')
              end
            end

            context 'with all discussions resolved' do
              before do
                merge_request.discussions.each { |d| d.resolve!(user) }
                expect(merge_request).to be_discussions_resolved
              end

              it 'returns :success' do
                merge_with_sha

                expect(json_response).to eq('status' => 'success')
              end
            end
          end

          context 'when disabled' do
            before do
              project.update_column(:only_allow_merge_if_all_discussions_are_resolved, false)
            end

            context 'with unresolved discussion' do
              before do
                expect(merge_request).not_to be_discussions_resolved
              end

              it 'returns :success' do
                merge_with_sha

                expect(json_response).to eq('status' => 'success')
              end
            end

            context 'with all discussions resolved' do
              before do
                merge_request.discussions.each { |d| d.resolve!(user) }
                expect(merge_request).to be_discussions_resolved
              end

              it 'returns :success' do
                merge_with_sha

                expect(json_response).to eq('status' => 'success')
              end
            end
          end
        end
      end
    end

    # TODO: Delete when removing old widget parts
    context 'as any other format' do
      let(:format) { 'js' }

      context 'when the user does not have access' do
        before do
          project.team.truncate
          project.team << [user, :reporter]
          post :merge, base_params
        end

        it 'returns not found' do
          expect(response).to be_not_found
        end
      end

      context 'when the merge request is not mergeable' do
        before do
          merge_request.update_attributes(title: "WIP: #{merge_request.title}")

          post :merge, base_params
        end

        it 'returns :failed' do
          expect(assigns(:status)).to eq(:failed)
        end
      end

      context 'when the sha parameter does not match the source SHA' do
        before { post :merge, base_params.merge(sha: 'foo') }

        it 'returns :sha_mismatch' do
          expect(assigns(:status)).to eq(:sha_mismatch)
        end
      end

      context 'when the sha parameter matches the source SHA' do
        def merge_with_sha
          post :merge, base_params.merge(sha: merge_request.diff_head_sha)
        end

        it 'returns :success' do
          merge_with_sha

          expect(assigns(:status)).to eq(:success)
        end

        it 'starts the merge immediately' do
          expect(MergeWorker).to receive(:perform_async).with(merge_request.id, anything, anything)

          merge_with_sha
        end

        context 'when the pipeline succeeds is passed' do
          def merge_when_pipeline_succeeds
            post :merge, base_params.merge(sha: merge_request.diff_head_sha, merge_when_pipeline_succeeds: '1')
          end

          before do
            create(:ci_empty_pipeline, project: project, sha: merge_request.diff_head_sha, ref: merge_request.source_branch)
          end

          it 'returns :merge_when_pipeline_succeeds' do
            merge_when_pipeline_succeeds

            expect(assigns(:status)).to eq(:merge_when_pipeline_succeeds)
          end

          it 'sets the MR to merge when the pipeline succeeds' do
            service = double(:merge_when_pipeline_succeeds_service)

            expect(MergeRequests::MergeWhenPipelineSucceedsService)
              .to receive(:new).with(project, anything, anything)
              .and_return(service)
            expect(service).to receive(:execute).with(merge_request)

            merge_when_pipeline_succeeds
          end

          context 'when project.only_allow_merge_if_pipeline_succeeds? is true' do
            before do
              project.update_column(:only_allow_merge_if_pipeline_succeeds, true)
            end

            it 'returns :merge_when_pipeline_succeeds' do
              merge_when_pipeline_succeeds

              expect(assigns(:status)).to eq(:merge_when_pipeline_succeeds)
            end
          end
        end

        describe 'only_allow_merge_if_all_discussions_are_resolved? setting' do
          let(:merge_request) { create(:merge_request_with_diff_notes, source_project: project, author: user) }

          context 'when enabled' do
            before do
              project.update_column(:only_allow_merge_if_all_discussions_are_resolved, true)
            end

            context 'with unresolved discussion' do
              before do
                expect(merge_request).not_to be_discussions_resolved
              end

              it 'returns :failed' do
                merge_with_sha

                expect(assigns(:status)).to eq(:failed)
              end
            end

            context 'with all discussions resolved' do
              before do
                merge_request.discussions.each { |d| d.resolve!(user) }
                expect(merge_request).to be_discussions_resolved
              end

              it 'returns :success' do
                merge_with_sha

                expect(assigns(:status)).to eq(:success)
              end
            end
          end

          context 'when disabled' do
            before do
              project.update_column(:only_allow_merge_if_all_discussions_are_resolved, false)
            end

            context 'with unresolved discussion' do
              before do
                expect(merge_request).not_to be_discussions_resolved
              end

              it 'returns :success' do
                merge_with_sha

                expect(assigns(:status)).to eq(:success)
              end
            end

            context 'with all discussions resolved' do
              before do
                merge_request.discussions.each { |d| d.resolve!(user) }
                expect(merge_request).to be_discussions_resolved
              end

              it 'returns :success' do
                merge_with_sha

                expect(assigns(:status)).to eq(:success)
              end
            end
          end
        end
      end
    end
  end

  describe "DELETE destroy" do
    it "denies access to users unless they're admin or project owner" do
      delete :destroy, namespace_id: project.namespace, project_id: project, id: merge_request.iid

      expect(response).to have_http_status(404)
    end

    context "when the user is owner" do
      let(:owner)     { create(:user) }
      let(:namespace) { create(:namespace, owner: owner) }
      let(:project)   { create(:project, namespace: namespace) }

      before { sign_in owner }

      it "deletes the merge request" do
        delete :destroy, namespace_id: project.namespace, project_id: project, id: merge_request.iid

        expect(response).to have_http_status(302)
        expect(controller).to set_flash[:notice].to(/The merge request was successfully deleted\./).now
      end

      it 'delegates the update of the todos count cache to TodoService' do
        expect_any_instance_of(TodoService).to receive(:destroy_merge_request).with(merge_request, owner).once

        delete :destroy, namespace_id: project.namespace, project_id: project, id: merge_request.iid
      end
    end
  end

  describe 'GET diffs' do
    def go(extra_params = {})
      params = {
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: merge_request.iid
      }

      get :diffs, params.merge(extra_params)
    end

    it_behaves_like "loads labels", :diffs

    context 'with default params' do
      context 'as html' do
        before { go(format: 'html') }

        it 'renders the diff template' do
          expect(response).to render_template('diffs')
        end
      end

      context 'as json' do
        before { go(format: 'json') }

        it 'renders the diffs template to a string' do
          expect(response).to render_template('projects/merge_requests/show/_diffs')
          expect(json_response).to have_key('html')
        end
      end

      context 'with forked projects with submodules' do
        render_views

        let(:project) { create(:project) }
        let(:fork_project) { create(:forked_project_with_submodules) }
        let(:merge_request) { create(:merge_request_with_diffs, source_project: fork_project, source_branch: 'add-submodule-version-bump', target_branch: 'master', target_project: project) }

        before do
          fork_project.build_forked_project_link(forked_to_project_id: fork_project.id, forked_from_project_id: project.id)
          fork_project.save
          merge_request.reload
          go(format: 'json')
        end

        it 'renders' do
          expect(response).to be_success
          expect(response.body).to have_content('Subproject commit')
        end
      end
    end

    context 'with ignore_whitespace_change' do
      context 'as html' do
        before { go(format: 'html', w: 1) }

        it 'renders the diff template' do
          expect(response).to render_template('diffs')
        end
      end

      context 'as json' do
        before { go(format: 'json', w: 1) }

        it 'renders the diffs template to a string' do
          expect(response).to render_template('projects/merge_requests/show/_diffs')
          expect(json_response).to have_key('html')
        end
      end
    end

    context 'with view' do
      before { go(view: 'parallel') }

      it 'saves the preferred diff view in a cookie' do
        expect(response.cookies['diff_view']).to eq('parallel')
      end
    end
  end

  describe 'GET diff_for_path' do
    def diff_for_path(extra_params = {})
      params = {
        namespace_id: project.namespace.to_param,
        project_id: project
      }

      get :diff_for_path, params.merge(extra_params)
    end

    context 'when an ID param is passed' do
      let(:existing_path) { 'files/ruby/popen.rb' }

      context 'when the merge request exists' do
        context 'when the user can view the merge request' do
          context 'when the path exists in the diff' do
            it 'enables diff notes' do
              diff_for_path(id: merge_request.iid, old_path: existing_path, new_path: existing_path)

              expect(assigns(:diff_notes_disabled)).to be_falsey
              expect(assigns(:comments_target)).to eq(noteable_type: 'MergeRequest',
                                                      noteable_id: merge_request.id)
            end

            it 'only renders the diffs for the path given' do
              expect(controller).to receive(:render_diff_for_path).and_wrap_original do |meth, diffs|
                expect(diffs.diff_files.map(&:new_path)).to contain_exactly(existing_path)
                meth.call(diffs)
              end

              diff_for_path(id: merge_request.iid, old_path: existing_path, new_path: existing_path)
            end
          end

          context 'when the path does not exist in the diff' do
            before { diff_for_path(id: merge_request.iid, old_path: 'files/ruby/nopen.rb', new_path: 'files/ruby/nopen.rb') }

            it 'returns a 404' do
              expect(response).to have_http_status(404)
            end
          end
        end

        context 'when the user cannot view the merge request' do
          before do
            project.team.truncate
            diff_for_path(id: merge_request.iid, old_path: existing_path, new_path: existing_path)
          end

          it 'returns a 404' do
            expect(response).to have_http_status(404)
          end
        end
      end

      context 'when the merge request does not exist' do
        before { diff_for_path(id: merge_request.iid.succ, old_path: existing_path, new_path: existing_path) }

        it 'returns a 404' do
          expect(response).to have_http_status(404)
        end
      end

      context 'when the merge request belongs to a different project' do
        let(:other_project) { create(:empty_project) }

        before do
          other_project.team << [user, :master]
          diff_for_path(id: merge_request.iid, old_path: existing_path, new_path: existing_path, project_id: other_project)
        end

        it 'returns a 404' do
          expect(response).to have_http_status(404)
        end
      end
    end

    context 'when source and target params are passed' do
      let(:existing_path) { 'files/ruby/feature.rb' }

      context 'when both branches are in the same project' do
        it 'disables diff notes' do
          diff_for_path(old_path: existing_path, new_path: existing_path, merge_request: { source_branch: 'feature', target_branch: 'master' })

          expect(assigns(:diff_notes_disabled)).to be_truthy
        end

        it 'only renders the diffs for the path given' do
          expect(controller).to receive(:render_diff_for_path).and_wrap_original do |meth, diffs|
            expect(diffs.diff_files.map(&:new_path)).to contain_exactly(existing_path)
            meth.call(diffs)
          end

          diff_for_path(old_path: existing_path, new_path: existing_path, merge_request: { source_branch: 'feature', target_branch: 'master' })
        end
      end

      context 'when the source branch is in a different project to the target' do
        let(:other_project) { create(:project) }

        before { other_project.team << [user, :master] }

        context 'when the path exists in the diff' do
          it 'disables diff notes' do
            diff_for_path(old_path: existing_path, new_path: existing_path, merge_request: { source_project: other_project, source_branch: 'feature', target_branch: 'master' })

            expect(assigns(:diff_notes_disabled)).to be_truthy
          end

          it 'only renders the diffs for the path given' do
            expect(controller).to receive(:render_diff_for_path).and_wrap_original do |meth, diffs|
              expect(diffs.diff_files.map(&:new_path)).to contain_exactly(existing_path)
              meth.call(diffs)
            end

            diff_for_path(old_path: existing_path, new_path: existing_path, merge_request: { source_project: other_project, source_branch: 'feature', target_branch: 'master' })
          end
        end

        context 'when the path does not exist in the diff' do
          before { diff_for_path(old_path: 'files/ruby/nopen.rb', new_path: 'files/ruby/nopen.rb', merge_request: { source_project: other_project, source_branch: 'feature', target_branch: 'master' }) }

          it 'returns a 404' do
            expect(response).to have_http_status(404)
          end
        end
      end
    end
  end

  describe 'GET commits' do
    def go(format: 'html')
      get :commits,
          namespace_id: project.namespace.to_param,
          project_id: project,
          id: merge_request.iid,
          format: format
    end

    it_behaves_like "loads labels", :commits

    context 'as html' do
      it 'renders the show template' do
        go

        expect(response).to render_template('show')
      end
    end

    context 'as json' do
      it 'renders the commits template to a string' do
        go format: 'json'

        expect(response).to render_template('projects/merge_requests/show/_commits')
        expect(json_response).to have_key('html')
      end
    end
  end

  describe 'GET pipelines' do
    before do
      create(:ci_pipeline, project: merge_request.source_project,
                           ref: merge_request.source_branch,
                           sha: merge_request.diff_head_sha)
    end

    context 'when using HTML format' do
      it_behaves_like "loads labels", :pipelines
    end

    context 'when using JSON format' do
      before do
        get :pipelines,
            namespace_id: project.namespace.to_param,
            project_id: project,
            id: merge_request.iid,
            format: :json
      end

      it 'responds with serialized pipelines' do
        expect(json_response).not_to be_empty
      end
    end
  end

  describe 'GET conflicts' do
    context 'when the conflicts cannot be resolved in the UI' do
      before do
        allow_any_instance_of(Gitlab::Conflict::Parser).
          to receive(:parse).and_raise(Gitlab::Conflict::Parser::UnmergeableFile)

        get :conflicts,
            namespace_id: merge_request_with_conflicts.project.namespace.to_param,
            project_id: merge_request_with_conflicts.project,
            id: merge_request_with_conflicts.iid,
            format: 'json'
      end

      it 'returns a 200 status code' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns JSON with a message' do
        expect(json_response.keys).to contain_exactly('message', 'type')
      end
    end

    context 'with valid conflicts' do
      before do
        get :conflicts,
            namespace_id: merge_request_with_conflicts.project.namespace.to_param,
            project_id: merge_request_with_conflicts.project,
            id: merge_request_with_conflicts.iid,
            format: 'json'
      end

      it 'matches the schema' do
        expect(response).to match_response_schema('conflicts')
      end

      it 'includes meta info about the MR' do
        expect(json_response['commit_message']).to include('Merge branch')
        expect(json_response['commit_sha']).to match(/\h{40}/)
        expect(json_response['source_branch']).to eq(merge_request_with_conflicts.source_branch)
        expect(json_response['target_branch']).to eq(merge_request_with_conflicts.target_branch)
      end

      it 'includes each file that has conflicts' do
        filenames = json_response['files'].map { |file| file['new_path'] }

        expect(filenames).to contain_exactly('files/ruby/popen.rb', 'files/ruby/regex.rb')
      end

      it 'splits files into sections with lines' do
        json_response['files'].each do |file|
          file['sections'].each do |section|
            expect(section).to include('conflict', 'lines')

            section['lines'].each do |line|
              if section['conflict']
                expect(line['type']).to be_in(%w(old new))
                expect(line.values_at('old_line', 'new_line')).to contain_exactly(nil, a_kind_of(Integer))
              else
                if line['type'].nil?
                  expect(line['old_line']).not_to eq(nil)
                  expect(line['new_line']).not_to eq(nil)
                else
                  expect(line['type']).to eq('match')
                  expect(line['old_line']).to eq(nil)
                  expect(line['new_line']).to eq(nil)
                end
              end
            end
          end
        end
      end

      it 'has unique section IDs across files' do
        section_ids = json_response['files'].flat_map do |file|
          file['sections'].map { |section| section['id'] }.compact
        end

        expect(section_ids.uniq).to eq(section_ids)
      end
    end
  end

  context 'POST remove_wip' do
    before do
      merge_request.title = merge_request.wip_title
      merge_request.save
    end

    context 'as HTML' do
      before do
        post :remove_wip,
          namespace_id: merge_request.project.namespace.to_param,
          project_id: merge_request.project,
          id: merge_request.iid
      end

      it 'removes the wip status' do
        expect(merge_request.reload.title).to eq(merge_request.wipless_title)
      end

      it 'redirect to merge request show page' do
        expect(response).to redirect_to(
          namespace_project_merge_request_path(merge_request.project.namespace,
                                               merge_request.project,
                                               merge_request))
      end
    end

    context 'as JSON' do
      before do
        xhr :post, :remove_wip,
          namespace_id: merge_request.project.namespace.to_param,
          project_id: merge_request.project,
          id: merge_request.iid,
          format: :json
      end

      it 'removes the wip status' do
        expect(merge_request.reload.title).to eq(merge_request.wipless_title)
      end

      it 'renders MergeRequest as JSON' do
        expect(json_response.keys).to include('id', 'iid', 'description')
      end
    end
  end

  describe 'POST cancel_merge_when_pipeline_succeeds' do
    context 'as JS' do
      subject do
        xhr :post, :cancel_merge_when_pipeline_succeeds,
          namespace_id: merge_request.project.namespace.to_param,
          project_id: merge_request.project,
          id: merge_request.iid
      end

      it 'calls MergeRequests::MergeWhenPipelineSucceedsService' do
        mwps_service = double

        allow(MergeRequests::MergeWhenPipelineSucceedsService)
          .to receive(:new)
          .and_return(mwps_service)

        expect(mwps_service).to receive(:cancel).with(merge_request)

        subject
      end

      it { is_expected.to render_template('cancel_merge_when_pipeline_succeeds') }
    end

    context 'as JSON' do
      subject do
        xhr :post, :cancel_merge_when_pipeline_succeeds,
          namespace_id: merge_request.project.namespace.to_param,
          project_id: merge_request.project,
          id: merge_request.iid,
          format: :json
      end

      it 'calls MergeRequests::MergeWhenPipelineSucceedsService' do
        mwps_service = double

        allow(MergeRequests::MergeWhenPipelineSucceedsService)
          .to receive(:new)
          .and_return(mwps_service)

        expect(mwps_service).to receive(:cancel).with(merge_request)

        subject
      end

      it { is_expected.to have_http_status(:success) }

      it 'renders MergeRequest as JSON' do
        subject

        expect(json_response.keys).to include('id', 'iid', 'description')
      end
    end
  end

  describe 'GET conflict_for_path' do
    def conflict_for_path(path)
      get :conflict_for_path,
          namespace_id: merge_request_with_conflicts.project.namespace.to_param,
          project_id: merge_request_with_conflicts.project,
          id: merge_request_with_conflicts.iid,
          old_path: path,
          new_path: path,
          format: 'json'
    end

    context 'when the conflicts cannot be resolved in the UI' do
      before do
        allow_any_instance_of(Gitlab::Conflict::Parser).
          to receive(:parse).and_raise(Gitlab::Conflict::Parser::UnmergeableFile)

        conflict_for_path('files/ruby/regex.rb')
      end

      it 'returns a 404 status code' do
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when the file does not exist cannot be resolved in the UI' do
      before { conflict_for_path('files/ruby/regexp.rb') }

      it 'returns a 404 status code' do
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'with an existing file' do
      let(:path) { 'files/ruby/regex.rb' }

      before { conflict_for_path(path) }

      it 'returns a 200 status code' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns the file in JSON format' do
        content = merge_request_with_conflicts.conflicts.file_for_path(path, path).content

        expect(json_response).to include('old_path' => path,
                                         'new_path' => path,
                                         'blob_icon' => 'file-text-o',
                                         'blob_path' => a_string_ending_with(path),
                                         'blob_ace_mode' => 'ruby',
                                         'content' => content)
      end
    end
  end

  context 'POST resolve_conflicts' do
    let!(:original_head_sha) { merge_request_with_conflicts.diff_head_sha }

    def resolve_conflicts(files)
      post :resolve_conflicts,
           namespace_id: merge_request_with_conflicts.project.namespace.to_param,
           project_id: merge_request_with_conflicts.project,
           id: merge_request_with_conflicts.iid,
           format: 'json',
           files: files,
           commit_message: 'Commit message'
    end

    context 'with valid params' do
      before do
        resolved_files = [
          {
            'new_path' => 'files/ruby/popen.rb',
            'old_path' => 'files/ruby/popen.rb',
            'sections' => {
              '2f6fcd96b88b36ce98c38da085c795a27d92a3dd_14_14' => 'head'
            }
          }, {
            'new_path' => 'files/ruby/regex.rb',
            'old_path' => 'files/ruby/regex.rb',
            'sections' => {
              '6eb14e00385d2fb284765eb1cd8d420d33d63fc9_9_9' => 'head',
              '6eb14e00385d2fb284765eb1cd8d420d33d63fc9_21_21' => 'origin',
              '6eb14e00385d2fb284765eb1cd8d420d33d63fc9_49_49' => 'origin'
            }
          }
        ]

        resolve_conflicts(resolved_files)
      end

      it 'creates a new commit on the branch' do
        expect(original_head_sha).not_to eq(merge_request_with_conflicts.source_branch_head.sha)
        expect(merge_request_with_conflicts.source_branch_head.message).to include('Commit message')
      end

      it 'returns an OK response' do
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when sections are missing' do
      before do
        resolved_files = [
          {
            'new_path' => 'files/ruby/popen.rb',
            'old_path' => 'files/ruby/popen.rb',
            'sections' => {
              '2f6fcd96b88b36ce98c38da085c795a27d92a3dd_14_14' => 'head'
            }
          }, {
            'new_path' => 'files/ruby/regex.rb',
            'old_path' => 'files/ruby/regex.rb',
            'sections' => {
              '6eb14e00385d2fb284765eb1cd8d420d33d63fc9_9_9' => 'head'
            }
          }
        ]

        resolve_conflicts(resolved_files)
      end

      it 'returns a 400 error' do
        expect(response).to have_http_status(:bad_request)
      end

      it 'has a message with the name of the first missing section' do
        expect(json_response['message']).to include('6eb14e00385d2fb284765eb1cd8d420d33d63fc9_21_21')
      end

      it 'does not create a new commit' do
        expect(original_head_sha).to eq(merge_request_with_conflicts.source_branch_head.sha)
      end
    end

    context 'when files are missing' do
      before do
        resolved_files = [
          {
            'new_path' => 'files/ruby/regex.rb',
            'old_path' => 'files/ruby/regex.rb',
            'sections' => {
              '6eb14e00385d2fb284765eb1cd8d420d33d63fc9_9_9' => 'head',
              '6eb14e00385d2fb284765eb1cd8d420d33d63fc9_21_21' => 'origin',
              '6eb14e00385d2fb284765eb1cd8d420d33d63fc9_49_49' => 'origin'
            }
          }
        ]

        resolve_conflicts(resolved_files)
      end

      it 'returns a 400 error' do
        expect(response).to have_http_status(:bad_request)
      end

      it 'has a message with the name of the missing file' do
        expect(json_response['message']).to include('files/ruby/popen.rb')
      end

      it 'does not create a new commit' do
        expect(original_head_sha).to eq(merge_request_with_conflicts.source_branch_head.sha)
      end
    end

    context 'when a file has identical content to the conflict' do
      before do
        resolved_files = [
          {
            'new_path' => 'files/ruby/popen.rb',
            'old_path' => 'files/ruby/popen.rb',
            'content' => merge_request_with_conflicts.conflicts.file_for_path('files/ruby/popen.rb', 'files/ruby/popen.rb').content
          }, {
            'new_path' => 'files/ruby/regex.rb',
            'old_path' => 'files/ruby/regex.rb',
            'sections' => {
              '6eb14e00385d2fb284765eb1cd8d420d33d63fc9_9_9' => 'head',
              '6eb14e00385d2fb284765eb1cd8d420d33d63fc9_21_21' => 'origin',
              '6eb14e00385d2fb284765eb1cd8d420d33d63fc9_49_49' => 'origin'
            }
          }
        ]

        resolve_conflicts(resolved_files)
      end

      it 'returns a 400 error' do
        expect(response).to have_http_status(:bad_request)
      end

      it 'has a message with the path of the problem file' do
        expect(json_response['message']).to include('files/ruby/popen.rb')
      end

      it 'does not create a new commit' do
        expect(original_head_sha).to eq(merge_request_with_conflicts.source_branch_head.sha)
      end
    end
  end

  describe 'POST assign_related_issues' do
    let(:issue1) { create(:issue, project: project) }
    let(:issue2) { create(:issue, project: project) }

    def post_assign_issues
      merge_request.update!(description: "Closes #{issue1.to_reference} and #{issue2.to_reference}",
                            author: user,
                            source_branch: 'feature',
                            target_branch: 'master')

      post :assign_related_issues,
           namespace_id: project.namespace.to_param,
           project_id: project,
           id: merge_request.iid
    end

    it 'shows a flash message on success' do
      post_assign_issues

      expect(flash[:notice]).to eq '2 issues have been assigned to you'
    end

    it 'correctly pluralizes flash message on success' do
      issue2.update!(assignee: user)

      post_assign_issues

      expect(flash[:notice]).to eq '1 issue has been assigned to you'
    end

    it 'calls MergeRequests::AssignIssuesService' do
      expect(MergeRequests::AssignIssuesService).to receive(:new).
        with(project, user, merge_request: merge_request).
        and_return(double(execute: { count: 1 }))

      post_assign_issues
    end

    it 'is skipped when not signed in' do
      project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
      sign_out(:user)

      expect(MergeRequests::AssignIssuesService).not_to receive(:new)

      post_assign_issues
    end
  end

  describe 'GET ci_environments_status' do
    context 'the environment is from a forked project' do
      let!(:forked)       { create(:project) }
      let!(:environment)  { create(:environment, project: forked) }
      let!(:deployment)   { create(:deployment, environment: environment, sha: forked.commit.id, ref: 'master') }
      let(:admin)         { create(:admin) }

      let(:merge_request) do
        create(:forked_project_link, forked_to_project: forked,
                                     forked_from_project: project)

        create(:merge_request, source_project: forked, target_project: project)
      end

      before do
        forked.team << [user, :master]

        get :ci_environments_status,
          namespace_id: merge_request.project.namespace.to_param,
          project_id: merge_request.project,
          id: merge_request.iid, format: 'json'
      end

      it 'links to the environment on that project' do
        expect(json_response.first['url']).to match /#{forked.path_with_namespace}/
      end
    end
  end

  describe 'GET merge_widget_refresh' do
    let(:params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        id: merge_request.iid,
        format: :raw
      }
    end

    before do
      project.team << [user, :developer]
      xhr :get, :merge_widget_refresh, params
    end

    context 'when merge in progress' do
      let(:merge_request) { create(:merge_request, source_project: project, in_progress_merge_commit_sha: 'sha') }

      it 'returns an OK response' do
        expect(response).to have_http_status(:ok)
      end

      it 'sets status to :success' do
        expect(assigns(:status)).to eq(:success)
        expect(response).to render_template('merge')
      end
    end

    context 'when merge request was merged already' do
      let(:merge_request) { create(:merge_request, source_project: project, state: :merged) }

      it 'returns an OK response' do
        expect(response).to have_http_status(:ok)
      end

      it 'sets status to :success' do
        expect(assigns(:status)).to eq(:success)
        expect(response).to render_template('merge')
      end
    end

    context 'when waiting for build' do
      let(:merge_request) { create(:merge_request, source_project: project, merge_when_pipeline_succeeds: true, merge_user: user) }

      it 'returns an OK response' do
        expect(response).to have_http_status(:ok)
      end

      it 'sets status to :merge_when_pipeline_succeeds' do
        expect(assigns(:status)).to eq(:merge_when_pipeline_succeeds)
        expect(response).to render_template('merge')
      end
    end

    context 'when MR does not have special state' do
      let(:merge_request) { create(:merge_request, source_project: project) }

      it 'returns an OK response' do
        expect(response).to have_http_status(:ok)
      end

      it 'sets status to success' do
        expect(assigns(:status)).to eq(:success)
        expect(response).to render_template('merge')
      end
    end
  end

  describe 'GET pipeline_status.json' do
    context 'when head_pipeline exists' do
      let!(:pipeline) do
        create(:ci_pipeline, project: merge_request.source_project,
                             ref: merge_request.source_branch,
                             sha: merge_request.diff_head_sha)
      end

      let(:status) { pipeline.detailed_status(double('user')) }

      before { get_pipeline_status }

      it 'return a detailed head_pipeline status in json' do
        expect(response).to have_http_status(:ok)
        expect(json_response['text']).to eq status.text
        expect(json_response['label']).to eq status.label
        expect(json_response['icon']).to eq status.icon
        expect(json_response['favicon']).to eq status.favicon
      end
    end

    context 'when head_pipeline does not exist' do
      before { get_pipeline_status }

      it 'return empty' do
        expect(response).to have_http_status(:ok)
        expect(json_response).to be_empty
      end
    end

    def get_pipeline_status
      get :pipeline_status, namespace_id: project.namespace,
                            project_id: project,
                            id: merge_request.iid,
                            format: :json
    end
  end
end
