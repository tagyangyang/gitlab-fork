require 'spec_helper'

describe Ci::CreatePipelineService, services: true do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:admin) }

  before do
    stub_ci_pipeline_to_return_yaml_file
  end

  describe '#execute' do
    def execute_service(after: project.commit.id, message: 'Message', ref: 'refs/heads/master')
      params = { ref: ref,
                 before: '00000000',
                 after: after,
                 commits: [{ message: message }] }

      described_class.new(project, user, params).execute
    end

    context 'valid params' do
      let(:pipeline) { execute_service }

      let(:pipeline_on_previous_commit) do
        execute_service(
          after: previous_commit_sha_from_ref('master')
        )
      end

      it { expect(pipeline).to be_kind_of(Ci::Pipeline) }
      it { expect(pipeline).to be_valid }
      it { expect(pipeline).to eq(project.pipelines.last) }
      it { expect(pipeline).to have_attributes(user: user) }
      it { expect(pipeline).to have_attributes(status: 'pending') }
      it { expect(pipeline.builds.first).to be_kind_of(Ci::Build) }

      context 'auto-cancel enabled' do
        before do
          project.update(auto_cancel_pending_pipelines: 'enabled')
        end

        it 'does not cancel HEAD pipeline' do
          pipeline
          pipeline_on_previous_commit

          expect(pipeline.reload).to have_attributes(status: 'pending', auto_canceled_by_id: nil)
        end

        it 'auto cancel pending non-HEAD pipelines' do
          pipeline_on_previous_commit
          pipeline

          expect(pipeline_on_previous_commit.reload).to have_attributes(status: 'canceled', auto_canceled_by_id: pipeline.id)
        end

        it 'does not cancel running outdated pipelines' do
          pipeline_on_previous_commit.run
          execute_service

          expect(pipeline_on_previous_commit.reload).to have_attributes(status: 'running', auto_canceled_by_id: nil)
        end

        it 'cancel created outdated pipelines' do
          pipeline_on_previous_commit.update(status: 'created')
          pipeline

          expect(pipeline_on_previous_commit.reload).to have_attributes(status: 'canceled', auto_canceled_by_id: pipeline.id)
        end

        it 'does not cancel pipelines from the other branches' do
          pending_pipeline = execute_service(
            ref: 'refs/heads/feature',
            after: previous_commit_sha_from_ref('feature')
          )
          pipeline

          expect(pending_pipeline.reload).to have_attributes(status: 'pending', auto_canceled_by_id: nil)
        end
      end

      context 'auto-cancel disabled' do
        before do
          project.update(auto_cancel_pending_pipelines: 'disabled')
        end

        it 'does not auto cancel pending non-HEAD pipelines' do
          pipeline_on_previous_commit
          pipeline

          expect(pipeline_on_previous_commit.reload)
            .to have_attributes(status: 'pending', auto_canceled_by_id: nil)
        end
      end

      def previous_commit_sha_from_ref(ref)
        project.commit(ref).parent.sha
      end
    end

    context "skip tag if there is no build for it" do
      it "creates commit if there is appropriate job" do
        expect(execute_service).to be_persisted
      end

      it "creates commit if there is no appropriate job but deploy job has right ref setting" do
        config = YAML.dump({ deploy: { script: "ls", only: ["master"] } })
        stub_ci_pipeline_yaml_file(config)

        expect(execute_service).to be_persisted
      end
    end

    it 'skips creating pipeline for refs without .gitlab-ci.yml' do
      stub_ci_pipeline_yaml_file(nil)

      expect(execute_service).not_to be_persisted
      expect(Ci::Pipeline.count).to eq(0)
    end

    shared_examples 'a failed pipeline' do
      it 'creates failed pipeline' do
        stub_ci_pipeline_yaml_file(ci_yaml)

        pipeline = execute_service(message: message)

        expect(pipeline).to be_persisted
        expect(pipeline.builds.any?).to be false
        expect(pipeline.status).to eq('failed')
        expect(pipeline.yaml_errors).not_to be_nil
      end
    end

    context 'when yaml is invalid' do
      let(:ci_yaml) { 'invalid: file: fiile' }
      let(:message) { 'Message' }

      it_behaves_like 'a failed pipeline'

      context 'when receive git commit' do
        before do
          allow_any_instance_of(Ci::Pipeline).to receive(:git_commit_message) { message }
        end

        it_behaves_like 'a failed pipeline'
      end
    end

    context 'when commit contains a [ci skip] directive' do
      let(:message) { "some message[ci skip]" }

      ci_messages = [
        "some message[ci skip]",
        "some message[skip ci]",
        "some message[CI SKIP]",
        "some message[SKIP CI]",
        "some message[ci_skip]",
        "some message[skip_ci]",
        "some message[ci-skip]",
        "some message[skip-ci]"
      ]

      before do
        allow_any_instance_of(Ci::Pipeline).to receive(:git_commit_message) { message }
      end

      ci_messages.each do |ci_message|
        it "skips builds creation if the commit message is #{ci_message}" do
          pipeline = execute_service(message: ci_message)

          expect(pipeline).to be_persisted
          expect(pipeline.builds.any?).to be false
          expect(pipeline.status).to eq("skipped")
        end
      end

      shared_examples 'creating a pipeline' do
        it 'does not skip pipeline creation' do
          allow_any_instance_of(Ci::Pipeline).to receive(:git_commit_message) { commit_message }

          pipeline = execute_service(message: commit_message)

          expect(pipeline).to be_persisted
          expect(pipeline.builds.first.name).to eq("rspec")
        end
      end

      context 'when commit message does not contain [ci skip] nor [skip ci]' do
        let(:commit_message) { 'some message' }

        it_behaves_like 'creating a pipeline'
      end

      context 'when commit message is nil' do
        let(:commit_message) { nil }

        it_behaves_like 'creating a pipeline'
      end

      context 'when there is [ci skip] tag in commit message and yaml is invalid' do
        let(:ci_yaml) { 'invalid: file: fiile' }

        it_behaves_like 'a failed pipeline'
      end
    end

    context 'when there are no jobs for this pipeline' do
      before do
        config = YAML.dump({ test: { script: 'ls', only: ['feature'] } })
        stub_ci_pipeline_yaml_file(config)
      end

      it 'does not create a new pipeline' do
        result = execute_service

        expect(result).not_to be_persisted
        expect(Ci::Build.all).to be_empty
        expect(Ci::Pipeline.count).to eq(0)
      end
    end

    context 'with manual actions' do
      before do
        config = YAML.dump({ deploy: { script: 'ls', when: 'manual' } })
        stub_ci_pipeline_yaml_file(config)
      end

      it 'does not create a new pipeline' do
        result = execute_service

        expect(result).to be_persisted
        expect(result.manual_actions).not_to be_empty
      end
    end

    context 'with environment' do
      before do
        config = YAML.dump(deploy: { environment: { name: "review/$CI_COMMIT_REF_NAME" }, script: 'ls' })
        stub_ci_pipeline_yaml_file(config)
      end

      it 'creates the environment' do
        result = execute_service

        expect(result).to be_persisted
        expect(Environment.find_by(name: "review/master")).not_to be_nil
      end
    end
  end
end
