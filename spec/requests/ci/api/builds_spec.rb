require 'spec_helper'

describe Ci::API::Builds do
  include ApiHelpers

  let(:runner) { FactoryGirl.create(:ci_runner, tag_list: %w(mysql ruby)) }
  let(:project) { FactoryGirl.create(:empty_project, shared_runners_enabled: false) }
  let(:last_update) { nil }

  describe "Builds API for runners" do
    let(:pipeline) { create(:ci_pipeline_without_jobs, project: project, ref: 'master') }

    before do
      project.runners << runner
    end

    describe "POST /builds/register" do
      let!(:build) { create(:ci_build, pipeline: pipeline, name: 'spinach', stage: 'test', stage_idx: 0) }
      let(:user_agent) { 'gitlab-ci-multi-runner 1.5.2 (1-5-stable; go1.6.3; linux/amd64)' }
      let!(:last_update) { }
      let!(:new_update) { }

      before do
        stub_container_registry_config(enabled: false)
      end

      shared_examples 'no builds available' do
        context 'when runner sends version in User-Agent' do
          context 'for stable version' do
            it 'gives 204 and set X-GitLab-Last-Update' do
              expect(response).to have_http_status(204)
              expect(response.header).to have_key('X-GitLab-Last-Update')
            end
          end

          context 'when last_update is up-to-date' do
            let(:last_update) { runner.ensure_runner_queue_value }

            it 'gives 204 and set the same X-GitLab-Last-Update' do
              expect(response).to have_http_status(204)
              expect(response.header['X-GitLab-Last-Update'])
                .to eq(last_update)
            end
          end

          context 'when last_update is outdated' do
            let(:last_update) { runner.ensure_runner_queue_value }
            let(:new_update) { runner.tick_runner_queue }

            it 'gives 204 and set a new X-GitLab-Last-Update' do
              expect(response).to have_http_status(204)
              expect(response.header['X-GitLab-Last-Update'])
                .to eq(new_update)
            end
          end

          context 'for beta version' do
            let(:user_agent) { 'gitlab-ci-multi-runner 1.6.0~beta.167.g2b2bacc (1-5-stable; go1.6.3; linux/amd64)' }
            it { expect(response).to have_http_status(204) }
          end
        end

        context "when runner doesn't send version in User-Agent" do
          let(:user_agent) { 'Go-http-client/1.1' }
          it { expect(response).to have_http_status(404) }
        end

        context "when runner doesn't have a User-Agent" do
          let(:user_agent) { nil }
          it { expect(response).to have_http_status(404) }
        end
      end

      context 'when there is a pending build' do
        it 'starts a build' do
          register_builds info: { platform: :darwin }

          expect(response).to have_http_status(201)
          expect(response.headers).not_to have_key('X-GitLab-Last-Update')
          expect(json_response['sha']).to eq(build.sha)
          expect(runner.reload.platform).to eq("darwin")
          expect(json_response["options"]).to eq({ "image" => "ruby:2.1", "services" => ["postgres"] })
          expect(json_response["variables"]).to include(
            { "key" => "CI_JOB_NAME", "value" => "spinach", "public" => true },
            { "key" => "CI_JOB_STAGE", "value" => "test", "public" => true },
            { "key" => "DB_NAME", "value" => "postgres", "public" => true }
          )
        end

        it 'updates runner info' do
          expect { register_builds }.to change { runner.reload.contacted_at }
        end

        context 'when concurrently updating build' do
          before do
            expect_any_instance_of(Ci::Build).to receive(:run!).
              and_raise(ActiveRecord::StaleObjectError.new(nil, nil))
          end

          it 'returns a conflict' do
            register_builds info: { platform: :darwin }

            expect(response).to have_http_status(409)
            expect(response.headers).not_to have_key('X-GitLab-Last-Update')
          end
        end

        context 'registry credentials' do
          let(:registry_credentials) do
            { 'type' => 'registry',
              'url' => 'registry.example.com:5005',
              'username' => 'gitlab-ci-token',
              'password' => build.token }
          end

          context 'when registry is enabled' do
            before do
              stub_container_registry_config(enabled: true, host_port: 'registry.example.com:5005')
            end

            it 'sends registry credentials key' do
              register_builds info: { platform: :darwin }

              expect(json_response).to have_key('credentials')
              expect(json_response['credentials']).to include(registry_credentials)
            end
          end

          context 'when registry is disabled' do
            before do
              stub_container_registry_config(enabled: false, host_port: 'registry.example.com:5005')
            end

            it 'does not send registry credentials' do
              register_builds info: { platform: :darwin }

              expect(json_response).to have_key('credentials')
              expect(json_response['credentials']).not_to include(registry_credentials)
            end
          end
        end
      end

      context 'when builds are finished' do
        before do
          build.success
          register_builds
        end

        it_behaves_like 'no builds available'
      end

      context 'for other project with builds' do
        before do
          build.success
          create(:ci_build, :pending)
          register_builds
        end

        it_behaves_like 'no builds available'
      end

      context 'for shared runner' do
        let!(:runner) { create(:ci_runner, :shared, token: "SharedRunner") }

        before do
          register_builds(runner.token)
        end

        it_behaves_like 'no builds available'
      end

      context 'for triggered build' do
        before do
          trigger = create(:ci_trigger, project: project)
          create(:ci_trigger_request_with_variables, pipeline: pipeline, builds: [build], trigger: trigger)
          project.variables << Ci::Variable.new(key: "SECRET_KEY", value: "secret_value")
        end

        it "returns variables for triggers" do
          register_builds info: { platform: :darwin }

          expect(response).to have_http_status(201)
          expect(json_response["variables"]).to include(
            { "key" => "CI_JOB_NAME", "value" => "spinach", "public" => true },
            { "key" => "CI_JOB_STAGE", "value" => "test", "public" => true },
            { "key" => "CI_PIPELINE_TRIGGERED", "value" => "true", "public" => true },
            { "key" => "DB_NAME", "value" => "postgres", "public" => true },
            { "key" => "SECRET_KEY", "value" => "secret_value", "public" => false },
            { "key" => "TRIGGER_KEY_1", "value" => "TRIGGER_VALUE_1", "public" => false },
          )
        end
      end

      context 'with multiple builds' do
        before do
          build.success
        end

        let!(:test_build) { create(:ci_build, pipeline: pipeline, name: 'deploy', stage: 'deploy', stage_idx: 1) }

        it "returns dependent builds" do
          register_builds info: { platform: :darwin }

          expect(response).to have_http_status(201)
          expect(json_response["id"]).to eq(test_build.id)
          expect(json_response["depends_on_builds"].count).to eq(1)
          expect(json_response["depends_on_builds"][0]).to include('id' => build.id, 'name' => 'spinach')
        end
      end

      %w(name version revision platform architecture).each do |param|
        context "updates runner #{param}" do
          let(:value) { "#{param}_value" }

          subject { runner.read_attribute(param.to_sym) }

          it do
            register_builds info: { param => value }

            expect(response).to have_http_status(201)
            runner.reload
            is_expected.to eq(value)
          end
        end
      end

      context 'when build has no tags' do
        before do
          build.update(tags: [])
        end

        context 'when runner is allowed to pick untagged builds' do
          before { runner.update_column(:run_untagged, true) }

          it 'picks build' do
            register_builds

            expect(response).to have_http_status 201
          end
        end

        context 'when runner is not allowed to pick untagged builds' do
          before do
            runner.update_column(:run_untagged, false)
            register_builds
          end

          it_behaves_like 'no builds available'
        end
      end

      context 'when runner is paused' do
        let(:runner) { create(:ci_runner, :inactive, token: 'InactiveRunner') }

        it 'responds with 404' do
          register_builds

          expect(response).to have_http_status 404
        end

        it 'does not update runner info' do
          expect { register_builds }
            .not_to change { runner.reload.contacted_at }
        end
      end

      def register_builds(token = runner.token, **params)
        new_params = params.merge(token: token, last_update: last_update)

        post ci_api("/builds/register"), new_params, { 'User-Agent' => user_agent }
      end
    end

    describe "PUT /builds/:id" do
      let(:build) { create(:ci_build, :pending, :trace, pipeline: pipeline, runner_id: runner.id) }

      before do
        build.run!
        put ci_api("/builds/#{build.id}"), token: runner.token
      end

      it "updates a running build" do
        expect(response).to have_http_status(200)
      end

      it 'does not override trace information when no trace is given' do
        expect(build.reload.trace.raw).to eq 'BUILD TRACE'
      end

      context 'job has been erased' do
        let(:build) { create(:ci_build, runner_id: runner.id, erased_at: Time.now) }

        it 'responds with forbidden' do
          expect(response.status).to eq 403
        end
      end
    end

    describe 'PATCH /builds/:id/trace.txt' do
      let(:build) do
        attributes = { runner_id: runner.id, pipeline: pipeline }
        create(:ci_build, :running, :trace, attributes)
      end

      let(:headers) { { Ci::API::Helpers::BUILD_TOKEN_HEADER => build.token, 'Content-Type' => 'text/plain' } }
      let(:headers_with_range) { headers.merge({ 'Content-Range' => '11-20' }) }
      let(:update_interval) { 10.seconds.to_i }

      def patch_the_trace(content = ' appended', request_headers = nil)
        unless request_headers
          build.trace.read do |stream|
            offset = stream.size
            limit = offset + content.length - 1
            request_headers = headers.merge({ 'Content-Range' => "#{offset}-#{limit}" })
          end
        end

        Timecop.travel(build.updated_at + update_interval) do
          patch ci_api("/builds/#{build.id}/trace.txt"), content, request_headers
          build.reload
        end
      end

      def initial_patch_the_trace
        patch_the_trace(' appended', headers_with_range)
      end

      def force_patch_the_trace
        2.times { patch_the_trace('') }
      end

      before do
        initial_patch_the_trace
      end

      context 'when request is valid' do
        it 'gets correct response' do
          expect(response.status).to eq 202
          expect(build.reload.trace.raw).to eq 'BUILD TRACE appended'
          expect(response.header).to have_key 'Range'
          expect(response.header).to have_key 'Build-Status'
        end

        context 'when build has been updated recently' do
          it { expect{ patch_the_trace }.not_to change { build.updated_at }}

          it 'changes the build trace' do
            patch_the_trace

            expect(build.reload.trace.raw).to eq 'BUILD TRACE appended appended'
          end

          context 'when Runner makes a force-patch' do
            it { expect{ force_patch_the_trace }.not_to change { build.updated_at }}

            it "doesn't change the build.trace" do
              force_patch_the_trace

              expect(build.reload.trace.raw).to eq 'BUILD TRACE appended'
            end
          end
        end

        context 'when build was not updated recently' do
          let(:update_interval) { 15.minutes.to_i }

          it { expect { patch_the_trace }.to change { build.updated_at } }

          it 'changes the build.trace' do
            patch_the_trace

            expect(build.reload.trace.raw).to eq 'BUILD TRACE appended appended'
          end

          context 'when Runner makes a force-patch' do
            it { expect { force_patch_the_trace }.to change { build.updated_at } }

            it "doesn't change the build.trace" do
              force_patch_the_trace

              expect(build.reload.trace.raw).to eq 'BUILD TRACE appended'
            end
          end
        end

        context 'when project for the build has been deleted' do
          let(:build) do
            attributes = { runner_id: runner.id, pipeline: pipeline }
            create(:ci_build, :running, :trace, attributes) do |build|
              build.project.update(pending_delete: true)
            end
          end

          it 'responds with forbidden' do
            expect(response.status).to eq(403)
          end
        end
      end

      context 'when Runner makes a force-patch' do
        before do
          force_patch_the_trace
        end

        it 'gets correct response' do
          expect(response.status).to eq 202
          expect(build.reload.trace.raw).to eq 'BUILD TRACE appended'
          expect(response.header).to have_key 'Range'
          expect(response.header).to have_key 'Build-Status'
        end
      end

      context 'when content-range start is too big' do
        let(:headers_with_range) { headers.merge({ 'Content-Range' => '15-20' }) }

        it 'gets 416 error response with range headers' do
          expect(response.status).to eq 416
          expect(response.header).to have_key 'Range'
          expect(response.header['Range']).to eq '0-11'
        end
      end

      context 'when content-range start is too small' do
        let(:headers_with_range) { headers.merge({ 'Content-Range' => '8-20' }) }

        it 'gets 416 error response with range headers' do
          expect(response.status).to eq 416
          expect(response.header).to have_key 'Range'
          expect(response.header['Range']).to eq '0-11'
        end
      end

      context 'when Content-Range header is missing' do
        let(:headers_with_range) { headers }

        it { expect(response.status).to eq 400 }
      end

      context 'when build has been errased' do
        let(:build) { create(:ci_build, runner_id: runner.id, erased_at: Time.now) }

        it { expect(response.status).to eq 403 }
      end
    end

    context "Artifacts" do
      let(:file_upload) { fixture_file_upload(Rails.root + 'spec/fixtures/banana_sample.gif', 'image/gif') }
      let(:file_upload2) { fixture_file_upload(Rails.root + 'spec/fixtures/dk.png', 'image/gif') }
      let(:build) { create(:ci_build, :pending, pipeline: pipeline, runner_id: runner.id) }
      let(:authorize_url) { ci_api("/builds/#{build.id}/artifacts/authorize") }
      let(:post_url) { ci_api("/builds/#{build.id}/artifacts") }
      let(:delete_url) { ci_api("/builds/#{build.id}/artifacts") }
      let(:get_url) { ci_api("/builds/#{build.id}/artifacts") }
      let(:jwt_token) { JWT.encode({ 'iss' => 'gitlab-workhorse' }, Gitlab::Workhorse.secret, 'HS256') }
      let(:headers) { { "GitLab-Workhorse" => "1.0", Gitlab::Workhorse::INTERNAL_API_REQUEST_HEADER => jwt_token } }
      let(:token) { build.token }
      let(:headers_with_token) { headers.merge(Ci::API::Helpers::BUILD_TOKEN_HEADER => token) }

      before { build.run! }

      describe "POST /builds/:id/artifacts/authorize" do
        context "authorizes posting artifact to running build" do
          it "using token as parameter" do
            post authorize_url, { token: build.token }, headers

            expect(response).to have_http_status(200)
            expect(response.content_type.to_s).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
            expect(json_response["TempPath"]).not_to be_nil
          end

          it "using token as header" do
            post authorize_url, {}, headers_with_token

            expect(response).to have_http_status(200)
            expect(response.content_type.to_s).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
            expect(json_response["TempPath"]).not_to be_nil
          end

          it "using runners token" do
            post authorize_url, { token: build.project.runners_token }, headers

            expect(response).to have_http_status(200)
            expect(response.content_type.to_s).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
            expect(json_response["TempPath"]).not_to be_nil
          end

          it "reject requests that did not go through gitlab-workhorse" do
            headers.delete(Gitlab::Workhorse::INTERNAL_API_REQUEST_HEADER)

            post authorize_url, { token: build.token }, headers

            expect(response).to have_http_status(500)
          end
        end

        context "fails to post too large artifact" do
          it "using token as parameter" do
            stub_application_setting(max_artifacts_size: 0)

            post authorize_url, { token: build.token, filesize: 100 }, headers

            expect(response).to have_http_status(413)
          end

          it "using token as header" do
            stub_application_setting(max_artifacts_size: 0)

            post authorize_url, { filesize: 100 }, headers_with_token

            expect(response).to have_http_status(413)
          end
        end

        context 'authorization token is invalid' do
          before { post authorize_url, { token: 'invalid', filesize: 100 } }

          it 'responds with forbidden' do
            expect(response).to have_http_status(403)
          end
        end
      end

      describe "POST /builds/:id/artifacts" do
        context "disable sanitizer" do
          before do
            # by configuring this path we allow to pass temp file from any path
            allow(ArtifactUploader).to receive(:artifacts_upload_path).and_return('/')
          end

          describe 'build has been erased' do
            let(:build) { create(:ci_build, erased_at: Time.now) }

            before do
              upload_artifacts(file_upload, headers_with_token)
            end

            it 'responds with forbidden' do
              expect(response.status).to eq 403
            end
          end

          describe 'uploading artifacts for a running build' do
            shared_examples 'successful artifacts upload' do
              it 'updates successfully' do
                response_filename =
                  json_response['artifacts_file']['filename']

                expect(response).to have_http_status(201)
                expect(response_filename).to eq(file_upload.original_filename)
              end
            end

            context 'uses regular file post' do
              before do
                upload_artifacts(file_upload, headers_with_token, false)
              end

              it_behaves_like 'successful artifacts upload'
            end

            context 'uses accelerated file post' do
              before do
                upload_artifacts(file_upload, headers_with_token, true)
              end

              it_behaves_like 'successful artifacts upload'
            end

            context 'updates artifact' do
              before do
                upload_artifacts(file_upload2, headers_with_token)
                upload_artifacts(file_upload, headers_with_token)
              end

              it_behaves_like 'successful artifacts upload'
            end

            context 'when using runners token' do
              let(:token) { build.project.runners_token }

              before do
                upload_artifacts(file_upload, headers_with_token)
              end

              it_behaves_like 'successful artifacts upload'
            end
          end

          context 'posts artifacts file and metadata file' do
            let!(:artifacts) { file_upload }
            let!(:metadata) { file_upload2 }

            let(:stored_artifacts_file) { build.reload.artifacts_file.file }
            let(:stored_metadata_file) { build.reload.artifacts_metadata.file }
            let(:stored_artifacts_size) { build.reload.artifacts_size }

            before do
              post(post_url, post_data, headers_with_token)
            end

            context 'posts data accelerated by workhorse is correct' do
              let(:post_data) do
                { 'file.path' => artifacts.path,
                  'file.name' => artifacts.original_filename,
                  'metadata.path' => metadata.path,
                  'metadata.name' => metadata.original_filename }
              end

              it 'stores artifacts and artifacts metadata' do
                expect(response).to have_http_status(201)
                expect(stored_artifacts_file.original_filename).to eq(artifacts.original_filename)
                expect(stored_metadata_file.original_filename).to eq(metadata.original_filename)
                expect(stored_artifacts_size).to eq(71759)
              end
            end

            context 'no artifacts file in post data' do
              let(:post_data) do
                { 'metadata' => metadata }
              end

              it 'is expected to respond with bad request' do
                expect(response).to have_http_status(400)
              end

              it 'does not store metadata' do
                expect(stored_metadata_file).to be_nil
              end
            end
          end

          context 'with an expire date' do
            let!(:artifacts) { file_upload }
            let(:default_artifacts_expire_in) {}

            let(:post_data) do
              { 'file.path' => artifacts.path,
                'file.name' => artifacts.original_filename,
                'expire_in' => expire_in }
            end

            before do
              stub_application_setting(
                default_artifacts_expire_in: default_artifacts_expire_in)

              post(post_url, post_data, headers_with_token)
            end

            context 'with an expire_in given' do
              let(:expire_in) { '7 days' }

              it 'updates when specified' do
                build.reload
                expect(response).to have_http_status(201)
                expect(json_response['artifacts_expire_at']).not_to be_empty
                expect(build.artifacts_expire_at).
                  to be_within(5.minutes).of(7.days.from_now)
              end
            end

            context 'with no expire_in given' do
              let(:expire_in) { nil }

              it 'ignores if not specified' do
                build.reload
                expect(response).to have_http_status(201)
                expect(json_response['artifacts_expire_at']).to be_nil
                expect(build.artifacts_expire_at).to be_nil
              end

              context 'with application default' do
                context 'default to 5 days' do
                  let(:default_artifacts_expire_in) { '5 days' }

                  it 'sets to application default' do
                    build.reload
                    expect(response).to have_http_status(201)
                    expect(json_response['artifacts_expire_at'])
                      .not_to be_empty
                    expect(build.artifacts_expire_at)
                      .to be_within(5.minutes).of(5.days.from_now)
                  end
                end

                context 'default to 0' do
                  let(:default_artifacts_expire_in) { '0' }

                  it 'does not set expire_in' do
                    build.reload
                    expect(response).to have_http_status(201)
                    expect(json_response['artifacts_expire_at']).to be_nil
                    expect(build.artifacts_expire_at).to be_nil
                  end
                end
              end
            end
          end

          context "artifacts file is too large" do
            it "fails to post too large artifact" do
              stub_application_setting(max_artifacts_size: 0)
              upload_artifacts(file_upload, headers_with_token)
              expect(response).to have_http_status(413)
            end
          end

          context "artifacts post request does not contain file" do
            it "fails to post artifacts without file" do
              post post_url, {}, headers_with_token
              expect(response).to have_http_status(400)
            end
          end

          context 'GitLab Workhorse is not configured' do
            it "fails to post artifacts without GitLab-Workhorse" do
              post post_url, { token: build.token }, {}
              expect(response).to have_http_status(403)
            end
          end
        end

        context "artifacts are being stored outside of tmp path" do
          before do
            # by configuring this path we allow to pass file from @tmpdir only
            # but all temporary files are stored in system tmp directory
            @tmpdir = Dir.mktmpdir
            allow(ArtifactUploader).to receive(:artifacts_upload_path).and_return(@tmpdir)
          end

          after do
            FileUtils.remove_entry @tmpdir
          end

          it "fails to post artifacts for outside of tmp path" do
            upload_artifacts(file_upload, headers_with_token)
            expect(response).to have_http_status(400)
          end
        end

        def upload_artifacts(file, headers = {}, accelerated = true)
          if accelerated
            post post_url, {
              'file.path' => file.path,
              'file.name' => file.original_filename
            }, headers
          else
            post post_url, { file: file }, headers
          end
        end
      end

      describe 'DELETE /builds/:id/artifacts' do
        let(:build) { create(:ci_build, :artifacts) }

        before do
          delete delete_url, token: build.token
        end

        shared_examples 'having removable artifacts' do
          it 'removes build artifacts' do
            build.reload

            expect(response).to have_http_status(200)
            expect(build.artifacts_file.exists?).to be_falsy
            expect(build.artifacts_metadata.exists?).to be_falsy
            expect(build.artifacts_size).to be_nil
          end
        end

        context 'when using build token' do
          before do
            delete delete_url, token: build.token
          end

          it_behaves_like 'having removable artifacts'
        end

        context 'when using runnners token' do
          before do
            delete delete_url, token: build.project.runners_token
          end

          it_behaves_like 'having removable artifacts'
        end
      end

      describe 'GET /builds/:id/artifacts' do
        before do
          get get_url, token: token
        end

        context 'build has artifacts' do
          let(:build) { create(:ci_build, :artifacts) }
          let(:download_headers) do
            { 'Content-Transfer-Encoding' => 'binary',
              'Content-Disposition' => 'attachment; filename=ci_build_artifacts.zip' }
          end

          shared_examples 'having downloadable artifacts' do
            it 'download artifacts' do
              expect(response).to have_http_status(200)
              expect(response.headers).to include download_headers
            end
          end

          context 'when using build token' do
            let(:token) { build.token }

            it_behaves_like 'having downloadable artifacts'
          end

          context 'when using runnners token' do
            let(:token) { build.project.runners_token }

            it_behaves_like 'having downloadable artifacts'
          end
        end

        context 'build does not has artifacts' do
          let(:token) { build.token }

          it 'responds with not found' do
            expect(response).to have_http_status(404)
          end
        end
      end
    end
  end
end
