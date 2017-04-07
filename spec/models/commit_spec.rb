require 'spec_helper'

describe Commit, models: true do
  let(:project) { create(:project, :public, :repository) }
  let(:commit)  { project.commit }

  describe 'modules' do
    subject { described_class }

    it { is_expected.to include_module(Mentionable) }
    it { is_expected.to include_module(Participable) }
    it { is_expected.to include_module(Referable) }
    it { is_expected.to include_module(StaticModel) }
  end

  describe '#author' do
    it 'looks up the author in a case-insensitive way' do
      user = create(:user, email: commit.author_email.upcase)
      expect(commit.author).to eq(user)
    end

    it 'caches the author' do
      user = create(:user, email: commit.author_email)
      expect(RequestStore).to receive(:active?).twice.and_return(true)
      expect_any_instance_of(Commit).to receive(:find_author_by_any_email).and_call_original

      expect(commit.author).to eq(user)
      key = "commit_author:#{commit.author_email}"
      expect(RequestStore.store[key]).to eq(user)

      expect(commit.author).to eq(user)
      RequestStore.store.clear
    end
  end

  describe '#to_reference' do
    let(:project) { create(:project, :repository, path: 'sample-project') }
    let(:commit)  { project.commit }

    it 'returns a String reference to the object' do
      expect(commit.to_reference).to eq commit.id
    end

    it 'supports a cross-project reference' do
      another_project = build(:project, :repository, name: 'another-project', namespace: project.namespace)
      expect(commit.to_reference(another_project)).to eq "sample-project@#{commit.id}"
    end
  end

  describe '#reference_link_text' do
    let(:project) { create(:project, :repository, path: 'sample-project') }
    let(:commit)  { project.commit }

    it 'returns a String reference to the object' do
      expect(commit.reference_link_text).to eq commit.short_id
    end

    it 'supports a cross-project reference' do
      another_project = build(:project, :repository, name: 'another-project', namespace: project.namespace)
      expect(commit.reference_link_text(another_project)).to eq "sample-project@#{commit.short_id}"
    end
  end

  describe '#title' do
    it "returns no_commit_message when safe_message is blank" do
      allow(commit).to receive(:safe_message).and_return('')
      expect(commit.title).to eq("--no commit message")
    end

    it "truncates a message without a newline at 80 characters" do
      message = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec sodales id felis id blandit. Vivamus egestas lacinia lacus, sed rutrum mauris.'

      allow(commit).to receive(:safe_message).and_return(message)
      expect(commit.title).to eq("#{message[0..79]}…")
    end

    it "truncates a message with a newline before 80 characters at the newline" do
      message = commit.safe_message.split(" ").first

      allow(commit).to receive(:safe_message).and_return(message + "\n" + message)
      expect(commit.title).to eq(message)
    end

    it "does not truncates a message with a newline after 80 but less 100 characters" do
      message = <<eos
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec sodales id felis id blandit.
Vivamus egestas lacinia lacus, sed rutrum mauris.
eos

      allow(commit).to receive(:safe_message).and_return(message)
      expect(commit.title).to eq(message.split("\n").first)
    end
  end

  describe '#full_title' do
    it "returns no_commit_message when safe_message is blank" do
      allow(commit).to receive(:safe_message).and_return('')
      expect(commit.full_title).to eq("--no commit message")
    end

    it "returns entire message if there is no newline" do
      message = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec sodales id felis id blandit. Vivamus egestas lacinia lacus, sed rutrum mauris.'

      allow(commit).to receive(:safe_message).and_return(message)
      expect(commit.full_title).to eq(message)
    end

    it "returns first line of message if there is a newLine" do
      message = commit.safe_message.split(" ").first

      allow(commit).to receive(:safe_message).and_return(message + "\n" + message)
      expect(commit.full_title).to eq(message)
    end
  end

  describe "delegation" do
    subject { commit }

    it { is_expected.to respond_to(:message) }
    it { is_expected.to respond_to(:authored_date) }
    it { is_expected.to respond_to(:committed_date) }
    it { is_expected.to respond_to(:committer_email) }
    it { is_expected.to respond_to(:author_email) }
    it { is_expected.to respond_to(:parents) }
    it { is_expected.to respond_to(:date) }
    it { is_expected.to respond_to(:diffs) }
    it { is_expected.to respond_to(:tree) }
    it { is_expected.to respond_to(:id) }
    it { is_expected.to respond_to(:to_patch) }
  end

  describe '#closes_issues' do
    let(:issue) { create :issue, project: project }
    let(:other_project) { create(:empty_project, :public) }
    let(:other_issue) { create :issue, project: other_project }
    let(:commiter) { create :user }

    before do
      project.team << [commiter, :developer]
      other_project.team << [commiter, :developer]
    end

    it 'detects issues that this commit is marked as closing' do
      ext_ref = "#{other_project.path_with_namespace}##{other_issue.iid}"

      allow(commit).to receive_messages(
        safe_message: "Fixes ##{issue.iid} and #{ext_ref}",
        committer_email: commiter.email
      )

      expect(commit.closes_issues).to include(issue)
      expect(commit.closes_issues).to include(other_issue)
    end
  end

  it_behaves_like 'a mentionable' do
    subject { create(:project, :repository).commit }

    let(:author) { create(:user, email: subject.author_email) }
    let(:backref_text) { "commit #{subject.id}" }
    let(:set_mentionable_text) do
      ->(txt) { allow(subject).to receive(:safe_message).and_return(txt) }
    end

    # Include the subject in the repository stub.
    let(:extra_commits) { [subject] }
  end

  describe '#hook_attrs' do
    let(:data) { commit.hook_attrs(with_changed_files: true) }

    it { expect(data).to be_a(Hash) }
    it { expect(data[:message]).to include('adds bar folder and branch-test text file to check Repository merged_to_root_ref method') }
    it { expect(data[:timestamp]).to eq('2016-09-27T14:37:46+00:00') }
    it { expect(data[:added]).to eq(["bar/branch-test.txt"]) }
    it { expect(data[:modified]).to eq([]) }
    it { expect(data[:removed]).to eq([]) }
  end

  describe '#reverts_commit?' do
    let(:another_commit) { double(:commit, revert_description: "This reverts commit #{commit.sha}") }
    let(:user) { commit.author }

    it { expect(commit.reverts_commit?(another_commit, user)).to be_falsy }

    context 'commit has no description' do
      before { allow(commit).to receive(:description?).and_return(false) }

      it { expect(commit.reverts_commit?(another_commit, user)).to be_falsy }
    end

    context "another_commit's description does not revert commit" do
      before { allow(commit).to receive(:description).and_return("Foo Bar") }

      it { expect(commit.reverts_commit?(another_commit, user)).to be_falsy }
    end

    context "another_commit's description reverts commit" do
      before { allow(commit).to receive(:description).and_return("Foo #{another_commit.revert_description} Bar") }

      it { expect(commit.reverts_commit?(another_commit, user)).to be_truthy }
    end

    context "another_commit's description reverts merged merge request" do
      before do
        revert_description = "This reverts merge request !foo123"
        allow(another_commit).to receive(:revert_description).and_return(revert_description)
        allow(commit).to receive(:description).and_return("Foo #{another_commit.revert_description} Bar")
      end

      it { expect(commit.reverts_commit?(another_commit, user)).to be_truthy }
    end
  end

  describe '#latest_pipeline' do
    let!(:first_pipeline) do
      create(:ci_empty_pipeline,
        project: project,
        sha: commit.sha,
        status: 'success')
    end
    let!(:second_pipeline) do
      create(:ci_empty_pipeline,
        project: project,
        sha: commit.sha,
        status: 'success')
    end

    it 'returns latest pipeline' do
      expect(commit.latest_pipeline).to eq second_pipeline
    end
  end

  describe '#status' do
    context 'without ref argument' do
      before do
        %w[success failed created pending].each do |status|
          create(:ci_empty_pipeline,
                 project: project,
                 sha: commit.sha,
                 status: status)
        end
      end

      it 'gives compound status from latest pipelines' do
        expect(commit.status).to eq(Ci::Pipeline.latest_status)
        expect(commit.status).to eq('pending')
      end
    end

    context 'when a particular ref is specified' do
      let!(:pipeline_from_master) do
        create(:ci_empty_pipeline,
               project: project,
               sha: commit.sha,
               ref: 'master',
               status: 'failed')
      end

      let!(:pipeline_from_fix) do
        create(:ci_empty_pipeline,
               project: project,
               sha: commit.sha,
               ref: 'fix',
               status: 'success')
      end

      it 'gives pipelines from a particular branch' do
        expect(commit.status('master')).to eq(pipeline_from_master.status)
        expect(commit.status('fix')).to eq(pipeline_from_fix.status)
      end

      it 'gives compound status from latest pipelines if ref is nil' do
        expect(commit.status(nil)).to eq(Ci::Pipeline.latest_status)
        expect(commit.status(nil)).to eq('failed')
      end
    end
  end

  describe '#participants' do
    let(:user1) { build(:user) }
    let(:user2) { build(:user) }

    let!(:note1) do
      create(:note_on_commit,
             commit_id: commit.id,
             project: project,
             note: 'foo')
    end

    let!(:note2) do
      create(:note_on_commit,
             commit_id: commit.id,
             project: project,
             note: 'bar')
    end

    before do
      allow(commit).to receive(:author).and_return(user1)
      allow(commit).to receive(:committer).and_return(user2)
    end

    it 'includes the commit author' do
      expect(commit.participants).to include(commit.author)
    end

    it 'includes the committer' do
      expect(commit.participants).to include(commit.committer)
    end

    it 'includes the authors of the commit notes' do
      expect(commit.participants).to include(note1.author, note2.author)
    end
  end

  describe '#uri_type' do
    it 'returns the URI type at the given path' do
      expect(commit.uri_type('files/html')).to be(:tree)
      expect(commit.uri_type('files/images/logo-black.png')).to be(:raw)
      expect(project.commit('video').uri_type('files/videos/intro.mp4')).to be(:raw)
      expect(commit.uri_type('files/js/application.js')).to be(:blob)
    end

    it "returns nil if the path doesn't exists" do
      expect(commit.uri_type('this/path/doesnt/exist')).to be_nil
    end
  end

  describe '.from_hash' do
    let(:new_commit) { described_class.from_hash(commit.to_hash, project) }

    it 'returns a Commit' do
      expect(new_commit).to be_an_instance_of(described_class)
    end

    it 'wraps a Gitlab::Git::Commit' do
      expect(new_commit.raw).to be_an_instance_of(Gitlab::Git::Commit)
    end

    it 'stores the correct commit fields' do
      expect(new_commit.id).to eq(commit.id)
      expect(new_commit.message).to eq(commit.message)
    end
  end

  describe '#work_in_progress?' do
    ['squash! ', 'fixup! ', 'wip: ', 'WIP: ', '[WIP] '].each do |wip_prefix|
      it "detects the '#{wip_prefix}' prefix" do
        commit.message = "#{wip_prefix}#{commit.message}"

        expect(commit).to be_work_in_progress
      end
    end

    it "detects WIP for a commit just saying 'wip'" do
      commit.message = "wip"

      expect(commit).to be_work_in_progress
    end

    it "doesn't detect WIP for a commit that begins with 'FIXUP! '" do
      commit.message = "FIXUP! #{commit.message}"

      expect(commit).not_to be_work_in_progress
    end

    it "doesn't detect WIP for words starting with WIP" do
      commit.message = "Wipout #{commit.message}"

      expect(commit).not_to be_work_in_progress
    end
  end

  describe '.valid_hash?' do
    it 'checks hash contents' do
      expect(described_class.valid_hash?('abcdef01239ABCDEF')).to be true
      expect(described_class.valid_hash?("abcdef01239ABCD\nEF")).to be false
      expect(described_class.valid_hash?(' abcdef01239ABCDEF ')).to be false
      expect(described_class.valid_hash?('Gabcdef01239ABCDEF')).to be false
      expect(described_class.valid_hash?('gabcdef01239ABCDEF')).to be false
      expect(described_class.valid_hash?('-abcdef01239ABCDEF')).to be false
    end

    it 'checks hash length' do
      expect(described_class.valid_hash?('a' * 6)).to be false
      expect(described_class.valid_hash?('a' * 7)).to be true
      expect(described_class.valid_hash?('a' * 40)).to be true
      expect(described_class.valid_hash?('a' * 41)).to be false
    end
  end

  # describe '#raw_diffs' do
  # TODO: Uncomment when feature is reenabled
  #   context 'Gitaly commit_raw_diffs feature enabled' do
  #     before do
  #       allow(Gitlab::GitalyClient).to receive(:feature_enabled?).with(:commit_raw_diffs).and_return(true)
  #     end
  #
  #     context 'when a truthy deltas_only is not passed to args' do
  #       it 'fetches diffs from Gitaly server' do
  #         expect(Gitlab::GitalyClient::Commit).to receive(:diff_from_parent).
  #           with(commit)
  #
  #         commit.raw_diffs
  #       end
  #     end
  #
  #     context 'when a truthy deltas_only is passed to args' do
  #       it 'fetches diffs using Rugged' do
  #         opts = { deltas_only: true }
  #
  #         expect(Gitlab::GitalyClient::Commit).not_to receive(:diff_from_parent)
  #         expect(commit.raw).to receive(:diffs).with(opts)
  #
  #         commit.raw_diffs(opts)
  #       end
  #     end
  #   end
  # end
end
