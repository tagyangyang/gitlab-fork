require 'spec_helper'

describe 'projects/builds/show', :view do
  let(:project) { create(:project, :repository) }
  let(:build) { create(:ci_build, pipeline: pipeline) }

  let(:pipeline) do
    create(:ci_pipeline, project: project, sha: project.commit.id)
  end

  before do
    assign(:build, build.present)
    assign(:project, project)

    allow(view).to receive(:can?).and_return(true)
  end

  describe 'job information in header' do
    let(:build) do
      create(:ci_build, :success, environment: 'staging')
    end

    before do
      render
    end

    it 'shows status name' do
      expect(rendered).to have_css('.ci-status.ci-success', text: 'passed')
    end

    it 'does not render a link to the job' do
      expect(rendered).not_to have_link('passed')
    end

    it 'shows job id' do
      expect(rendered).to have_css('.js-build-id', text: build.id)
    end

    it 'shows a link to the pipeline' do
      expect(rendered).to have_link(build.pipeline.id)
    end

    it 'shows a link to the commit' do
      expect(rendered).to have_link(build.pipeline.short_sha)
    end
  end

  describe 'environment info in job view' do
    context 'job with latest deployment' do
      let(:build) do
        create(:ci_build, :success, environment: 'staging')
      end

      before do
        create(:environment, name: 'staging')
        create(:deployment, deployable: build)
      end

      it 'shows deployment message' do
        expected_text = 'This job is the most recent deployment'
        render

        expect(rendered).to have_css(
          '.environment-information', text: expected_text)
      end
    end

    context 'job with outdated deployment' do
      let(:build) do
        create(:ci_build, :success, environment: 'staging', pipeline: pipeline)
      end

      let(:second_build) do
        create(:ci_build, :success, environment: 'staging', pipeline: pipeline)
      end

      let(:environment) do
        create(:environment, name: 'staging', project: project)
      end

      let!(:first_deployment) do
        create(:deployment, environment: environment, deployable: build)
      end

      let!(:second_deployment) do
        create(:deployment, environment: environment, deployable: second_build)
      end

      it 'shows deployment message' do
        expected_text = 'This job is an out-of-date deployment ' \
          "to staging.\nView the most recent deployment ##{second_deployment.iid}."
        render

        expect(rendered).to have_css('.environment-information', text: expected_text)
      end
    end

    context 'job failed to deploy' do
      let(:build) do
        create(:ci_build, :failed, environment: 'staging', pipeline: pipeline)
      end

      let!(:environment) do
        create(:environment, name: 'staging', project: project)
      end

      it 'shows deployment message' do
        expected_text = 'The deployment of this job to staging did not succeed.'
        render

        expect(rendered).to have_css(
          '.environment-information', text: expected_text)
      end
    end

    context 'job will deploy' do
      let(:build) do
        create(:ci_build, :running, environment: 'staging', pipeline: pipeline)
      end

      context 'when environment exists' do
        let!(:environment) do
          create(:environment, name: 'staging', project: project)
        end

        it 'shows deployment message' do
          expected_text = 'This job is creating a deployment to staging'
          render

          expect(rendered).to have_css(
            '.environment-information', text: expected_text)
        end

        context 'when it has deployment' do
          let!(:deployment) do
            create(:deployment, environment: environment)
          end

          it 'shows that deployment will be overwritten' do
            expected_text = 'This job is creating a deployment to staging'
            render

            expect(rendered).to have_css(
              '.environment-information', text: expected_text)
            expect(rendered).to have_css(
              '.environment-information', text: 'latest deployment')
          end
        end
      end

      context 'when environment does not exist' do
        it 'shows deployment message' do
          expected_text = 'This job is creating a deployment to staging'
          render

          expect(rendered).to have_css(
            '.environment-information', text: expected_text)
          expect(rendered).not_to have_css(
            '.environment-information', text: 'latest deployment')
        end
      end
    end

    context 'job that failed to deploy and environment has not been created' do
      let(:build) do
        create(:ci_build, :failed, environment: 'staging', pipeline: pipeline)
      end

      let!(:environment) do
        create(:environment, name: 'staging', project: project)
      end

      it 'shows deployment message' do
        expected_text = 'The deployment of this job to staging did not succeed'
        render

        expect(rendered).to have_css(
          '.environment-information', text: expected_text)
      end
    end

    context 'job that will deploy and environment has not been created' do
      let(:build) do
        create(:ci_build, :running, environment: 'staging', pipeline: pipeline)
      end

      let!(:environment) do
        create(:environment, name: 'staging', project: project)
      end

      it 'shows deployment message' do
        expected_text = 'This job is creating a deployment to staging'
        render

        expect(rendered).to have_css(
          '.environment-information', text: expected_text)
        expect(rendered).not_to have_css(
          '.environment-information', text: 'latest deployment')
      end
    end
  end

  context 'when job is running' do
    before do
      build.run!
      render
    end

    it 'does not show retry button' do
      expect(rendered).not_to have_link('Retry')
    end

    it 'does not show New issue button' do
      expect(rendered).not_to have_link('New issue')
    end
  end

  context 'when job is not running' do
    before do
      build.success!
      render
    end

    it 'shows retry button' do
      expect(rendered).to have_link('Retry')
    end

    context 'if build passed' do
      it 'does not show New issue button' do
        expect(rendered).not_to have_link('New issue')
      end
    end

    context 'if build failed' do
      before do
        build.status = 'failed'
        render
      end

      it 'shows New issue button' do
        expect(rendered).to have_link('New issue')
      end
    end
  end

  describe 'commit title in sidebar' do
    let(:commit_title) { project.commit.title }

    it 'shows commit title and not show commit message' do
      render

      expect(rendered).to have_css('p.build-light-text.append-bottom-0',
        text: /\A\n#{Regexp.escape(commit_title)}\n\Z/)
    end
  end

  describe 'shows trigger variables in sidebar' do
    let(:trigger_request) { create(:ci_trigger_request_with_variables, pipeline: pipeline) }

    before do
      build.trigger_request = trigger_request
      render
    end

    it 'shows trigger variables in separate lines' do
      expect(rendered).to have_css('.js-build-variable', visible: false, text: 'TRIGGER_KEY_1')
      expect(rendered).to have_css('.js-build-variable', visible: false, text: 'TRIGGER_KEY_2')
      expect(rendered).to have_css('.js-build-value', visible: false, text: 'TRIGGER_VALUE_1')
      expect(rendered).to have_css('.js-build-value', visible: false, text: 'TRIGGER_VALUE_2')
    end
  end

  describe 'New issue button' do
    before do
      build.status = 'failed'
      render
    end

    it 'links to issues/new with the title and description filled in' do
      title = "Build Failed ##{build.id}"
      build_url = namespace_project_build_url(project.namespace, project, build)
      href = new_namespace_project_issue_path(
        project.namespace,
        project,
        issue: {
          title: title,
          description: build_url
        }
      )
      expect(rendered).to have_link('New issue', href: href)
    end
  end
end
