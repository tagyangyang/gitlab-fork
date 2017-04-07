require 'spec_helper'

describe Gitlab::ProjectSearchResults, lib: true do
  let(:user) { create(:user) }
  let(:project) { create(:empty_project) }
  let(:query) { 'hello world' }

  describe 'initialize with empty ref' do
    let(:results) { described_class.new(user, project, query, '') }

    it { expect(results.project).to eq(project) }
    it { expect(results.query).to eq('hello world') }
  end

  describe 'initialize with ref' do
    let(:ref) { 'refs/heads/test' }
    let(:results) { described_class.new(user, project, query, ref) }

    it { expect(results.project).to eq(project) }
    it { expect(results.repository_ref).to eq(ref) }
    it { expect(results.query).to eq('hello world') }
  end

  describe 'blob search' do
    let(:project) { create(:project, :repository) }
    let(:results) { described_class.new(user, project, 'files').objects('blobs') }

    it 'finds by name' do
      expect(results).to include(["files/images/wm.svg", nil])
    end

    it 'finds by content' do
      blob = results.select { |result| result.first == "CHANGELOG" }.flatten.last

      expect(blob.filename).to eq("CHANGELOG")
    end

    describe 'parsing results' do
      let(:results) { project.repository.search_files_by_content('feature', 'master') }
      let(:search_result) { results.first }

      subject { described_class.parse_search_result(search_result) }

      it "returns a valid FoundBlob" do
        is_expected.to be_an Gitlab::SearchResults::FoundBlob
        expect(subject.id).to be_nil
        expect(subject.path).to eq('CHANGELOG')
        expect(subject.filename).to eq('CHANGELOG')
        expect(subject.basename).to eq('CHANGELOG')
        expect(subject.ref).to eq('master')
        expect(subject.startline).to eq(188)
        expect(subject.data.lines[2]).to eq("  - Feature: Replace teams with group membership\n")
      end

      context "when filename has extension" do
        let(:search_result) { "master:CONTRIBUTE.md:5:- [Contribute to GitLab](#contribute-to-gitlab)\n" }

        it { expect(subject.path).to eq('CONTRIBUTE.md') }
        it { expect(subject.filename).to eq('CONTRIBUTE.md') }
        it { expect(subject.basename).to eq('CONTRIBUTE') }
      end

      context "when file under directory" do
        let(:search_result) { "master:a/b/c.md:5:a b c\n" }

        it { expect(subject.path).to eq('a/b/c.md') }
        it { expect(subject.filename).to eq('a/b/c.md') }
        it { expect(subject.basename).to eq('a/b/c') }
      end
    end
  end

  it 'does not list issues on private projects' do
    issue = create(:issue, project: project)

    results = described_class.new(user, project, issue.title)

    expect(results.objects('issues')).not_to include issue
  end

  describe 'confidential issues' do
    let(:project) { create(:empty_project) }
    let(:query) { 'issue' }
    let(:author) { create(:user) }
    let(:assignee) { create(:user) }
    let(:non_member) { create(:user) }
    let(:member) { create(:user) }
    let(:admin) { create(:admin) }
    let(:project) { create(:empty_project, :internal) }
    let!(:issue) { create(:issue, project: project, title: 'Issue 1') }
    let!(:security_issue_1) { create(:issue, :confidential, project: project, title: 'Security issue 1', author: author) }
    let!(:security_issue_2) { create(:issue, :confidential, title: 'Security issue 2', project: project, assignee: assignee) }

    it 'does not list project confidential issues for non project members' do
      results = described_class.new(non_member, project, query)
      issues = results.objects('issues')

      expect(issues).to include issue
      expect(issues).not_to include security_issue_1
      expect(issues).not_to include security_issue_2
      expect(results.issues_count).to eq 1
    end

    it 'does not list project confidential issues for project members with guest role' do
      project.team << [member, :guest]

      results = described_class.new(member, project, query)
      issues = results.objects('issues')

      expect(issues).to include issue
      expect(issues).not_to include security_issue_1
      expect(issues).not_to include security_issue_2
      expect(results.issues_count).to eq 1
    end

    it 'lists project confidential issues for author' do
      results = described_class.new(author, project, query)
      issues = results.objects('issues')

      expect(issues).to include issue
      expect(issues).to include security_issue_1
      expect(issues).not_to include security_issue_2
      expect(results.issues_count).to eq 2
    end

    it 'lists project confidential issues for assignee' do
      results = described_class.new(assignee, project, query)
      issues = results.objects('issues')

      expect(issues).to include issue
      expect(issues).not_to include security_issue_1
      expect(issues).to include security_issue_2
      expect(results.issues_count).to eq 2
    end

    it 'lists project confidential issues for project members' do
      project.team << [member, :developer]

      results = described_class.new(member, project, query)
      issues = results.objects('issues')

      expect(issues).to include issue
      expect(issues).to include security_issue_1
      expect(issues).to include security_issue_2
      expect(results.issues_count).to eq 3
    end

    it 'lists all project issues for admin' do
      results = described_class.new(admin, project, query)
      issues = results.objects('issues')

      expect(issues).to include issue
      expect(issues).to include security_issue_1
      expect(issues).to include security_issue_2
      expect(results.issues_count).to eq 3
    end
  end

  describe 'notes search' do
    it 'lists notes' do
      project = create(:empty_project, :public)
      note = create(:note, project: project)

      results = described_class.new(user, project, note.note)

      expect(results.objects('notes')).to include note
    end

    it "doesn't list issue notes when access is restricted" do
      project = create(:empty_project, :public, :issues_private)
      note = create(:note_on_issue, project: project)

      results = described_class.new(user, project, note.note)

      expect(results.objects('notes')).not_to include note
    end

    it "doesn't list merge_request notes when access is restricted" do
      project = create(:empty_project, :public, :merge_requests_private)
      note = create(:note_on_merge_request, project: project)

      results = described_class.new(user, project, note.note)

      expect(results.objects('notes')).not_to include note
    end
  end

  # Examples for commit access level test
  #
  # params:
  # * search_phrase
  # * commit
  #
  shared_examples 'access restricted commits' do
    context 'when project is internal' do
      let(:project) { create(:project, :internal, :repository) }

      it 'does not search if user is not authenticated' do
        commits = described_class.new(nil, project, search_phrase).objects('commits')

        expect(commits).to be_empty
      end

      it 'searches if user is authenticated' do
        commits = described_class.new(user, project, search_phrase).objects('commits')

        expect(commits).to contain_exactly commit
      end
    end

    context 'when project is private' do
      let!(:creator) { create(:user, username: 'private-project-author') }
      let!(:private_project) { create(:project, :private, :repository, creator: creator, namespace: creator.namespace) }
      let(:team_master) do
        user = create(:user, username: 'private-project-master')
        private_project.team << [user, :master]
        user
      end
      let(:team_reporter) do
        user = create(:user, username: 'private-project-reporter')
        private_project.team << [user, :reporter]
        user
      end

      it 'does not show commit to stranger' do
        commits = described_class.new(nil, private_project, search_phrase).objects('commits')

        expect(commits).to be_empty
      end

      context 'team access' do
        it 'shows commit to creator' do
          commits = described_class.new(creator, private_project, search_phrase).objects('commits')

          expect(commits).to contain_exactly commit
        end

        it 'shows commit to master' do
          commits = described_class.new(team_master, private_project, search_phrase).objects('commits')

          expect(commits).to contain_exactly commit
        end

        it 'shows commit to reporter' do
          commits = described_class.new(team_reporter, private_project, search_phrase).objects('commits')

          expect(commits).to contain_exactly commit
        end
      end
    end
  end

  describe 'commit search' do
    context 'by commit message' do
      let(:project) { create(:project, :public, :repository) }
      let(:commit) { project.repository.commit('59e29889be61e6e0e5e223bfa9ac2721d31605b8') }
      let(:message) { 'Sorry, I did a mistake' }

      it 'finds commit by message' do
        commits = described_class.new(user, project, message).objects('commits')

        expect(commits).to contain_exactly commit
      end

      it 'handles when no commit match' do
        commits = described_class.new(user, project, 'not really an existing description').objects('commits')

        expect(commits).to be_empty
      end

      it_behaves_like 'access restricted commits' do
        let(:search_phrase) { message }
        let(:commit) { project.repository.commit('59e29889be61e6e0e5e223bfa9ac2721d31605b8') }
      end
    end

    context 'by commit hash' do
      let(:project) { create(:project, :public, :repository) }
      let(:commit) { project.repository.commit('0b4bc9a') }
      commit_hashes = { short: '0b4bc9a', full: '0b4bc9a49b562e85de7cc9e834518ea6828729b9' }

      commit_hashes.each do |type, commit_hash|
        it "shows commit by #{type} hash id" do
          commits = described_class.new(user, project, commit_hash).objects('commits')

          expect(commits).to contain_exactly commit
        end
      end

      it 'handles not existing commit hash correctly' do
        commits = described_class.new(user, project, 'deadbeef').objects('commits')

        expect(commits).to be_empty
      end

      it_behaves_like 'access restricted commits' do
        let(:search_phrase) { '0b4bc9a49' }
        let(:commit) { project.repository.commit('0b4bc9a') }
      end
    end
  end
end
