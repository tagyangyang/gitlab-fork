require 'spec_helper'

describe MoveToProjectFinder do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  let(:no_access_project) { create(:project) }
  let(:guess_project) { create(:project) }
  let(:reporter_project) { create(:project) }
  let(:developer_project) { create(:project) }
  let(:master_project) { create(:project) }

  subject { described_class.new(user) }

  describe '#execute' do
    context 'filter' do
      it 'does not return projects under Gitlab::Access::REPORTER' do
        guess_project.team << [user, :guest]

        expect(subject.execute(project)).to be_empty
      end

      it 'returns projects equal or above Gitlab::Access::REPORTER ordered by id desc' do
        reporter_project.team << [user, :reporter]
        developer_project.team << [user, :developer]
        master_project.team << [user, :master]

        expect(subject.execute(project).to_a).to eq([master_project, developer_project, reporter_project])
      end

      it 'does not return the project we pass (from the project we move the issue)' do
        project.team << [user, :reporter]

        expect(subject.execute(project).to_a).to be_empty
      end

      it 'does not return archived projects' do
        reporter_project.team << [user, :reporter]
        reporter_project.update_attributes(archived: true)
        other_reporter_project = create(:project)
        other_reporter_project.team << [user, :reporter]

        expect(subject.execute(project).to_a).to eq([other_reporter_project])
      end

      it 'does not return projects with issues disabled' do
        reporter_project.team << [user, :reporter]
        reporter_project.update_attributes(issues_enabled: false)
        other_reporter_project = create(:project)
        other_reporter_project.team << [user, :reporter]

        expect(subject.execute(project).to_a).to eq([other_reporter_project])
      end

      it 'returns a page of projects ordered by id desc' do
        stub_const 'MoveToProjectFinder::PAGE_SIZE', 2

        reporter_project.team << [user, :reporter]
        developer_project.team << [user, :developer]
        master_project.team << [user, :master]

        expect(subject.execute(project).to_a).to eq([master_project, developer_project])
      end

      it 'returns projects after the offset_id provided' do
        stub_const 'MoveToProjectFinder::PAGE_SIZE', 2

        reporter_project.team << [user, :reporter]
        developer_project.team << [user, :developer]
        master_project.team << [user, :master]

        expect(subject.execute(project, search: nil, offset_id: master_project.id).to_a).to eq([developer_project, reporter_project])
        expect(subject.execute(project, search: nil, offset_id: developer_project.id).to_a).to eq([reporter_project])
        expect(subject.execute(project, search: nil, offset_id: reporter_project.id).to_a).to be_empty
      end
    end

    context 'search' do
      it 'uses Project#search' do
        expect(user).to receive_message_chain(:can_admin_issue_projects, :search) { Project.all }

        subject.execute(project, search: 'wadus')
      end

      it 'returns searched projects' do
        foo_project = create(:project)
        foo_project.team << [user, :master]

        wadus_project = create(:project, name: 'wadus')
        wadus_project.team << [user, :master]

        expect(subject.execute(project).to_a).to eq([wadus_project, foo_project])
        expect(subject.execute(project, search: 'wadus').to_a).to eq([wadus_project])
      end
    end
  end
end
