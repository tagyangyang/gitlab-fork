require 'spec_helper'
include ImportExport::CommonUtil

describe Gitlab::ImportExport::ProjectTreeRestorer, services: true do
  describe 'restore project tree' do
    before(:context) do
      @user = create(:user)

      RSpec::Mocks.with_temporary_scope do
        @shared = Gitlab::ImportExport::Shared.new(relative_path: "", project_path: 'path')
        allow(@shared).to receive(:export_path).and_return('spec/lib/gitlab/import_export/')
        @project = create(:empty_project, :builds_disabled, :issues_disabled, name: 'project', path: 'project')
        project_tree_restorer = described_class.new(user: @user, shared: @shared, project: @project)
        @restored_project_json = project_tree_restorer.restore
      end
    end

    context 'JSON' do
      it 'restores models based on JSON' do
        expect(@restored_project_json).to be true
      end

      it 'restore correct project features' do
        project = Project.find_by_path('project')

        expect(project.project_feature.issues_access_level).to eq(ProjectFeature::DISABLED)
        expect(project.project_feature.builds_access_level).to eq(ProjectFeature::DISABLED)
        expect(project.project_feature.snippets_access_level).to eq(ProjectFeature::ENABLED)
        expect(project.project_feature.wiki_access_level).to eq(ProjectFeature::ENABLED)
        expect(project.project_feature.merge_requests_access_level).to eq(ProjectFeature::ENABLED)
      end

      it 'has the same label associated to two issues' do
        expect(ProjectLabel.find_by_title('test2').issues.count).to eq(2)
      end

      it 'has milestones associated to two separate issues' do
        expect(Milestone.find_by_description('test milestone').issues.count).to eq(2)
      end

      it 'creates a valid pipeline note' do
        expect(Ci::Pipeline.first.notes).not_to be_empty
      end

      it 'restores pipelines with missing ref' do
        expect(Ci::Pipeline.where(ref: nil)).not_to be_empty
      end

      it 'restores the correct event with symbolised data' do
        expect(Event.where.not(data: nil).first.data[:ref]).not_to be_empty
      end

      it 'preserves updated_at on issues' do
        issue = Issue.where(description: 'Aliquam enim illo et possimus.').first

        expect(issue.reload.updated_at.to_s).to eq('2016-06-14 15:02:47 UTC')
      end

      it 'contains the merge access levels on a protected branch' do
        expect(ProtectedBranch.first.merge_access_levels).not_to be_empty
      end

      it 'contains the push access levels on a protected branch' do
        expect(ProtectedBranch.first.push_access_levels).not_to be_empty
      end

      context 'event at forth level of the tree' do
        let(:event) { Event.where(title: 'test levels').first }

        it 'restores the event' do
          expect(event).not_to be_nil
        end

        it 'event belongs to note, belongs to merge request, belongs to a project' do
          expect(event.note.noteable.project).not_to be_nil
        end
      end

      it 'has the correct data for merge request st_diffs' do
        # makes sure we are renaming the custom method +utf8_st_diffs+ into +st_diffs+

        expect(MergeRequestDiff.where.not(st_diffs: nil).count).to eq(9)
      end

      it 'has the correct time for merge request st_commits' do
        st_commits = MergeRequestDiff.where.not(st_commits: nil).first.st_commits

        expect(st_commits.first[:committed_date]).to be_kind_of(Time)
      end

      it 'has labels associated to label links, associated to issues' do
        expect(Label.first.label_links.first.target).not_to be_nil
      end

      it 'has project labels' do
        expect(ProjectLabel.count).to eq(2)
      end

      it 'has no group labels' do
        expect(GroupLabel.count).to eq(0)
      end

      it 'has a project feature' do
        expect(@project.project_feature).not_to be_nil
      end

      it 'restores the correct service' do
        expect(CustomIssueTrackerService.first).not_to be_nil
      end

      context 'Merge requests' do
        it 'always has the new project as a target' do
          expect(MergeRequest.find_by_title('MR1').target_project).to eq(@project)
        end

        it 'has the same source project as originally if source/target are the same' do
          expect(MergeRequest.find_by_title('MR1').source_project).to eq(@project)
        end

        it 'has the new project as target if source/target differ' do
          expect(MergeRequest.find_by_title('MR2').target_project).to eq(@project)
        end

        it 'has no source if source/target differ' do
          expect(MergeRequest.find_by_title('MR2').source_project_id).to eq(-1)
        end
      end

      context 'tokens are regenerated' do
        it 'has a new CI trigger token' do
          expect(Ci::Trigger.where(token: 'cdbfasdf44a5958c83654733449e585')).to be_empty
        end

        it 'has a new CI build token' do
          expect(Ci::Build.where(token: 'abcd')).to be_empty
        end
      end

      context 'has restored the correct number of records' do
        it 'has the correct number of merge requests' do
          expect(@project.merge_requests.size).to eq(9)
        end

        it 'has the correct number of triggers' do
          expect(@project.triggers.size).to eq(1)
        end

        it 'has the correct number of pipelines and statuses' do
          expect(@project.pipelines.size).to eq(5)

          @project.pipelines.zip([2, 2, 2, 2, 2])
            .each do |(pipeline, expected_status_size)|
              expect(pipeline.statuses.size).to eq(expected_status_size)
            end
        end
      end
    end
  end

  context 'Light JSON' do
    let(:user) { create(:user) }
    let(:shared) { Gitlab::ImportExport::Shared.new(relative_path: "", project_path: 'path') }
    let!(:project) { create(:empty_project, :builds_disabled, :issues_disabled, name: 'project', path: 'project') }
    let(:project_tree_restorer) { described_class.new(user: user, shared: shared, project: project) }
    let(:restored_project_json) { project_tree_restorer.restore }

    before do
      allow(ImportExport).to receive(:project_filename).and_return('project.light.json')
      allow(shared).to receive(:export_path).and_return('spec/lib/gitlab/import_export/')
    end

    context 'project.json file access check' do
      it 'does not read a symlink' do
        Dir.mktmpdir do |tmpdir|
          setup_symlink(tmpdir, 'project.json')
          allow(shared).to receive(:export_path).and_call_original

          restored_project_json

          expect(shared.errors.first).not_to include('test')
        end
      end
    end

    context 'when there is an existing build with build token' do
      it 'restores project json correctly' do
        create(:ci_build, token: 'abcd')

        expect(restored_project_json).to be true
      end
    end

    context 'with group' do
      let!(:project) do
        create(:empty_project,
               :builds_disabled,
               :issues_disabled,
               name: 'project',
               path: 'project',
               group: create(:group))
      end

      before do
        restored_project_json
      end

      it 'has group labels' do
        expect(GroupLabel.count).to eq(1)
      end

      it 'has label priorities' do
        expect(GroupLabel.first.priorities).not_to be_empty
      end
    end
  end
end
