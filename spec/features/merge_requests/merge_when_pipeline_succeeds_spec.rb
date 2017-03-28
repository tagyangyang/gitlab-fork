require 'spec_helper'

feature 'Merge When Pipeline Succeeds', :feature, :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }

  let(:merge_request) do
    create(:merge_request_with_diffs, source_project: project,
                                      author: user,
                                      title: 'Bug NS-04')
  end

  let(:pipeline) do
    create(:ci_pipeline, project: project,
                         sha: merge_request.diff_head_sha,
                         ref: merge_request.source_branch)
  end

  before do
    project.add_master(user)
    merge_request.update(head_pipeline_id: pipeline.id)
  end

  context 'when there is active pipeline for merge request' do
    background do
      create(:ci_build, pipeline: pipeline)
    end

    before do
      login_as user
      visit_merge_request(merge_request)
    end

    it 'displays the Merge When Pipeline Succeeds button' do
      expect(page).to have_button "Merge When Pipeline Succeeds"
    end

    describe 'enabling Merge When Pipeline Succeeds' do
      shared_examples 'Merge When Pipeline Succeeds activator' do
        it 'activates the Merge When Pipeline Succeeds feature' do
          click_button "Merge When Pipeline Succeeds"

          expect(page).to have_content "Set by #{user.name} to be merged automatically when the pipeline succeeds."
          expect(page).to have_content "The source branch will not be removed."
          expect(page).to have_link "Cancel Automatic Merge"
          visit_merge_request(merge_request) # Needed to refresh the page
          expect(page).to have_content /enabled an automatic merge when the pipeline for \h{8} succeeds/i
        end
      end

      context "when enabled immediately" do
        it_behaves_like 'Merge When Pipeline Succeeds activator'
      end

      context 'when enabled after pipeline status changed' do
        before do
          pipeline.run!

          # We depend on merge request widget being reloaded
          # so we have to wait for asynchronous call to reload it
          # and have_content expectation handles that.
          #
          expect(page).to have_content "Pipeline ##{pipeline.id} running"
        end

        it_behaves_like 'Merge When Pipeline Succeeds activator'
      end

      context 'when enabled after it was previously canceled' do
        before do
          click_button "Merge When Pipeline Succeeds"
          click_link "Cancel Automatic Merge"
        end

        it_behaves_like 'Merge When Pipeline Succeeds activator'
      end

      context 'when it was enabled and then canceled' do
        let(:merge_request) do
          create(:merge_request_with_diffs,
                 :merge_when_pipeline_succeeds,
                   source_project: project,
                   title: 'Bug NS-04',
                   author: user,
                   merge_user: user)
        end

        before do
          click_link "Cancel Automatic Merge"
        end

        it_behaves_like 'Merge When Pipeline Succeeds activator'
      end
    end
  end

  context 'when merge when pipeline succeeds is enabled' do
    let(:merge_request) do
      create(:merge_request_with_diffs, :simple,  source_project: project,
                                                  author: user,
                                                  merge_user: user,
                                                  title: 'MepMep',
                                                  merge_when_pipeline_succeeds: true)
    end

    let!(:build) do
      create(:ci_build, pipeline: pipeline)
    end

    before do
      login_as user
      visit_merge_request(merge_request)
    end

    it 'allows to cancel the automatic merge' do
      click_link "Cancel Automatic Merge"

      expect(page).to have_button "Merge When Pipeline Succeeds"

      visit_merge_request(merge_request) # refresh the page
      expect(page).to have_content "canceled the automatic merge"
    end

    it "allows the user to remove the source branch" do
      expect(page).to have_link "Remove Source Branch When Merged"

      click_link "Remove Source Branch When Merged"
      expect(page).to have_content "The source branch will be removed"
    end

    context 'when pipeline succeeds' do
      background { build.success }

      it 'merges merge request' do
        visit_merge_request(merge_request) # refresh the page

        expect(page).to have_content 'The changes were merged'
        expect(merge_request.reload).to be_merged
      end
    end
  end

  context 'when pipeline is not active' do
    it "does not allow to enable merge when pipeline succeeds" do
      visit_merge_request(merge_request)

      expect(page).not_to have_link 'Merge When Pipeline Succeeds'
    end
  end

  def visit_merge_request(merge_request)
    visit namespace_project_merge_request_path(merge_request.project.namespace, merge_request.project, merge_request)
  end
end
