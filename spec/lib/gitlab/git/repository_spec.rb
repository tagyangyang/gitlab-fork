require "spec_helper"

describe Gitlab::Git::Repository, seed_helper: true do
  include Gitlab::Git::EncodingHelper

  let(:repository) { Gitlab::Git::Repository.new('default', TEST_REPO_PATH) }

  describe "Respond to" do
    subject { repository }

    it { is_expected.to respond_to(:raw) }
    it { is_expected.to respond_to(:rugged) }
    it { is_expected.to respond_to(:root_ref) }
    it { is_expected.to respond_to(:tags) }
  end

  describe '#root_ref' do
    context 'with gitaly disabled' do
      before { allow(Gitlab::GitalyClient).to receive(:feature_enabled?).and_return(false) }

      it 'calls #discover_default_branch' do
        expect(repository).to receive(:discover_default_branch)
        repository.root_ref
      end
    end

    # TODO: Uncomment when feature is reenabled
    # context 'with gitaly enabled' do
    #   before { stub_gitaly }
    #
    #   it 'gets the branch name from GitalyClient' do
    #     expect_any_instance_of(Gitlab::GitalyClient::Ref).to receive(:default_branch_name)
    #     repository.root_ref
    #   end
    #
    #   it 'wraps GRPC exceptions' do
    #     expect_any_instance_of(Gitlab::GitalyClient::Ref).to receive(:default_branch_name).
    #       and_raise(GRPC::Unknown)
    #     expect { repository.root_ref }.to raise_error(Gitlab::Git::CommandError)
    #   end
    # end
  end

  describe "#discover_default_branch" do
    let(:master) { 'master' }
    let(:feature) { 'feature' }
    let(:feature2) { 'feature2' }

    it "returns 'master' when master exists" do
      expect(repository).to receive(:branch_names).at_least(:once).and_return([feature, master])
      expect(repository.discover_default_branch).to eq('master')
    end

    it "returns non-master when master exists but default branch is set to something else" do
      File.write(File.join(repository.path, 'HEAD'), 'ref: refs/heads/feature')
      expect(repository).to receive(:branch_names).at_least(:once).and_return([feature, master])
      expect(repository.discover_default_branch).to eq('feature')
      File.write(File.join(repository.path, 'HEAD'), 'ref: refs/heads/master')
    end

    it "returns a non-master branch when only one exists" do
      expect(repository).to receive(:branch_names).at_least(:once).and_return([feature])
      expect(repository.discover_default_branch).to eq('feature')
    end

    it "returns a non-master branch when more than one exists and master does not" do
      expect(repository).to receive(:branch_names).at_least(:once).and_return([feature, feature2])
      expect(repository.discover_default_branch).to eq('feature')
    end

    it "returns nil when no branch exists" do
      expect(repository).to receive(:branch_names).at_least(:once).and_return([])
      expect(repository.discover_default_branch).to be_nil
    end
  end

  describe '#branch_names' do
    subject { repository.branch_names }

    it 'has SeedRepo::Repo::BRANCHES.size elements' do
      expect(subject.size).to eq(SeedRepo::Repo::BRANCHES.size)
    end
    it { is_expected.to include("master") }
    it { is_expected.not_to include("branch-from-space") }

    # TODO: Uncomment when feature is reenabled
    # context 'with gitaly enabled' do
    #   before { stub_gitaly }
    #
    #   it 'gets the branch names from GitalyClient' do
    #     expect_any_instance_of(Gitlab::GitalyClient::Ref).to receive(:branch_names)
    #     subject
    #   end
    #
    #   it 'wraps GRPC exceptions' do
    #     expect_any_instance_of(Gitlab::GitalyClient::Ref).to receive(:branch_names).
    #       and_raise(GRPC::Unknown)
    #     expect { subject }.to raise_error(Gitlab::Git::CommandError)
    #   end
    # end
  end

  describe '#tag_names' do
    subject { repository.tag_names }

    it { is_expected.to be_kind_of Array }
    it 'has SeedRepo::Repo::TAGS.size elements' do
      expect(subject.size).to eq(SeedRepo::Repo::TAGS.size)
    end

    describe '#last' do
      subject { super().last }
      it { is_expected.to eq("v1.2.1") }
    end
    it { is_expected.to include("v1.0.0") }
    it { is_expected.not_to include("v5.0.0") }

    # TODO: Uncomment when feature is reenabled
    # context 'with gitaly enabled' do
    #   before { stub_gitaly }
    #
    #   it 'gets the tag names from GitalyClient' do
    #     expect_any_instance_of(Gitlab::GitalyClient::Ref).to receive(:tag_names)
    #     subject
    #   end
    #
    #   it 'wraps GRPC exceptions' do
    #     expect_any_instance_of(Gitlab::GitalyClient::Ref).to receive(:tag_names).
    #       and_raise(GRPC::Unknown)
    #     expect { subject }.to raise_error(Gitlab::Git::CommandError)
    #   end
    # end
  end

  shared_examples 'archive check' do |extenstion|
    it { expect(metadata['ArchivePath']).to match(/tmp\/gitlab-git-test.git\/gitlab-git-test-master-#{SeedRepo::LastCommit::ID}/) }
    it { expect(metadata['ArchivePath']).to end_with extenstion }
  end

  describe '#archive_prefix' do
    let(:project_name) { 'project-name'}

    before do
      expect(repository).to receive(:name).once.and_return(project_name)
    end

    it 'returns parameterised string for a ref containing slashes' do
      prefix = repository.archive_prefix('test/branch', 'SHA')

      expect(prefix).to eq("#{project_name}-test-branch-SHA")
    end

    it 'returns correct string for a ref containing dots' do
      prefix = repository.archive_prefix('test.branch', 'SHA')

      expect(prefix).to eq("#{project_name}-test.branch-SHA")
    end
  end

  describe '#archive' do
    let(:metadata) { repository.archive_metadata('master', '/tmp') }

    it_should_behave_like 'archive check', '.tar.gz'
  end

  describe '#archive_zip' do
    let(:metadata) { repository.archive_metadata('master', '/tmp', 'zip') }

    it_should_behave_like 'archive check', '.zip'
  end

  describe '#archive_bz2' do
    let(:metadata) { repository.archive_metadata('master', '/tmp', 'tbz2') }

    it_should_behave_like 'archive check', '.tar.bz2'
  end

  describe '#archive_fallback' do
    let(:metadata) { repository.archive_metadata('master', '/tmp', 'madeup') }

    it_should_behave_like 'archive check', '.tar.gz'
  end

  describe '#size' do
    subject { repository.size }

    it { is_expected.to be < 2 }
  end

  describe '#has_commits?' do
    it { expect(repository.has_commits?).to be_truthy }
  end

  describe '#empty?' do
    it { expect(repository.empty?).to be_falsey }
  end

  describe '#bare?' do
    it { expect(repository.bare?).to be_truthy }
  end

  describe '#heads' do
    let(:heads) { repository.heads }
    subject { heads }

    it { is_expected.to be_kind_of Array }

    describe '#size' do
      subject { super().size }
      it { is_expected.to eq(SeedRepo::Repo::BRANCHES.size) }
    end

    context :head do
      subject { heads.first }

      describe '#name' do
        subject { super().name }
        it { is_expected.to eq("feature") }
      end

      context :commit do
        subject { heads.first.dereferenced_target.sha }

        it { is_expected.to eq("0b4bc9a49b562e85de7cc9e834518ea6828729b9") }
      end
    end
  end

  describe '#ref_names' do
    let(:ref_names) { repository.ref_names }
    subject { ref_names }

    it { is_expected.to be_kind_of Array }

    describe '#first' do
      subject { super().first }
      it { is_expected.to eq('feature') }
    end

    describe '#last' do
      subject { super().last }
      it { is_expected.to eq('v1.2.1') }
    end
  end

  describe '#search_files' do
    let(:results) { repository.search_files('rails', 'master') }
    subject { results }

    it { is_expected.to be_kind_of Array }

    describe '#first' do
      subject { super().first }
      it { is_expected.to be_kind_of Gitlab::Git::BlobSnippet }
    end

    context 'blob result' do
      subject { results.first }

      describe '#ref' do
        subject { super().ref }
        it { is_expected.to eq('master') }
      end

      describe '#filename' do
        subject { super().filename }
        it { is_expected.to eq('CHANGELOG') }
      end

      describe '#startline' do
        subject { super().startline }
        it { is_expected.to eq(35) }
      end

      describe '#data' do
        subject { super().data }
        it { is_expected.to include "Ability to filter by multiple labels" }
      end
    end
  end

  context '#submodules' do
    let(:repository) { Gitlab::Git::Repository.new('default', TEST_REPO_PATH) }

    context 'where repo has submodules' do
      let(:submodules) { repository.submodules('master') }
      let(:submodule) { submodules.first }

      it { expect(submodules).to be_kind_of Hash }
      it { expect(submodules.empty?).to be_falsey }

      it 'should have valid data' do
        expect(submodule).to eq([
          "six", {
            "id" => "409f37c4f05865e4fb208c771485f211a22c4c2d",
            "path" => "six",
            "url" => "git://github.com/randx/six.git"
          }
        ])
      end

      it 'should handle nested submodules correctly' do
        nested = submodules['nested/six']
        expect(nested['path']).to eq('nested/six')
        expect(nested['url']).to eq('git://github.com/randx/six.git')
        expect(nested['id']).to eq('24fb71c79fcabc63dfd8832b12ee3bf2bf06b196')
      end

      it 'should handle deeply nested submodules correctly' do
        nested = submodules['deeper/nested/six']
        expect(nested['path']).to eq('deeper/nested/six')
        expect(nested['url']).to eq('git://github.com/randx/six.git')
        expect(nested['id']).to eq('24fb71c79fcabc63dfd8832b12ee3bf2bf06b196')
      end

      it 'should not have an entry for an invalid submodule' do
        expect(submodules).not_to have_key('invalid/path')
      end

      it 'should not have an entry for an uncommited submodule dir' do
        submodules = repository.submodules('fix-existing-submodule-dir')
        expect(submodules).not_to have_key('submodule-existing-dir')
      end

      it 'should handle tags correctly' do
        submodules = repository.submodules('v1.2.1')

        expect(submodules.first).to eq([
          "six", {
            "id" => "409f37c4f05865e4fb208c771485f211a22c4c2d",
            "path" => "six",
            "url" => "git://github.com/randx/six.git"
          }
        ])
      end
    end

    context 'where repo doesn\'t have submodules' do
      let(:submodules) { repository.submodules('6d39438') }
      it 'should return an empty hash' do
        expect(submodules).to be_empty
      end
    end
  end

  describe '#commit_count' do
    it { expect(repository.commit_count("master")).to eq(25) }
    it { expect(repository.commit_count("feature")).to eq(9) }
  end

  describe "#reset" do
    change_path = File.join(SEED_STORAGE_PATH, TEST_NORMAL_REPO_PATH, "CHANGELOG")
    untracked_path = File.join(SEED_STORAGE_PATH, TEST_NORMAL_REPO_PATH, "UNTRACKED")
    tracked_path = File.join(SEED_STORAGE_PATH, TEST_NORMAL_REPO_PATH, "files", "ruby", "popen.rb")

    change_text = "New changelog text"
    untracked_text = "This file is untracked"

    reset_commit = SeedRepo::LastCommit::ID

    context "--hard" do
      before(:all) do
        # Modify a tracked file
        File.open(change_path, "w") do |f|
          f.write(change_text)
        end

        # Add an untracked file to the working directory
        File.open(untracked_path, "w") do |f|
          f.write(untracked_text)
        end

        @normal_repo = Gitlab::Git::Repository.new('default', TEST_NORMAL_REPO_PATH)
        @normal_repo.reset("HEAD", :hard)
      end

      it "should replace the working directory with the content of the index" do
        File.open(change_path, "r") do |f|
          expect(f.each_line.first).not_to eq(change_text)
        end

        File.open(tracked_path, "r") do |f|
          expect(f.each_line.to_a[8]).to include('raise RuntimeError, "System commands')
        end
      end

      it "should not touch untracked files" do
        expect(File.exist?(untracked_path)).to be_truthy
      end

      it "should move the HEAD to the correct commit" do
        new_head = @normal_repo.rugged.head.target.oid
        expect(new_head).to eq(reset_commit)
      end

      it "should move the tip of the master branch to the correct commit" do
        new_tip = @normal_repo.rugged.references["refs/heads/master"].
          target.oid

        expect(new_tip).to eq(reset_commit)
      end

      after(:all) do
        # Fast-forward to the original HEAD
        FileUtils.rm_rf(TEST_NORMAL_REPO_PATH)
        ensure_seeds
      end
    end
  end

  describe "#checkout" do
    new_branch = "foo_branch"

    context "-b" do
      before(:all) do
        @normal_repo = Gitlab::Git::Repository.new('default', TEST_NORMAL_REPO_PATH)
        @normal_repo.checkout(new_branch, { b: true }, "origin/feature")
      end

      it "should create a new branch" do
        expect(@normal_repo.rugged.branches[new_branch]).not_to be_nil
      end

      it "should move the HEAD to the correct commit" do
        expect(@normal_repo.rugged.head.target.oid).to(
          eq(@normal_repo.rugged.branches["origin/feature"].target.oid)
        )
      end

      it "should refresh the repo's #heads collection" do
        head_names = @normal_repo.heads.map { |h| h.name }
        expect(head_names).to include(new_branch)
      end

      after(:all) do
        FileUtils.rm_rf(TEST_NORMAL_REPO_PATH)
        ensure_seeds
      end
    end

    context "without -b" do
      context "and specifying a nonexistent branch" do
        it "should not do anything" do
          normal_repo = Gitlab::Git::Repository.new('default', TEST_NORMAL_REPO_PATH)

          expect { normal_repo.checkout(new_branch) }.to raise_error(Rugged::ReferenceError)
          expect(normal_repo.rugged.branches[new_branch]).to be_nil
          expect(normal_repo.rugged.head.target.oid).to(
            eq(normal_repo.rugged.branches["master"].target.oid)
          )

          head_names = normal_repo.heads.map { |h| h.name }
          expect(head_names).not_to include(new_branch)
        end

        after(:all) do
          FileUtils.rm_rf(TEST_NORMAL_REPO_PATH)
          ensure_seeds
        end
      end

      context "and with a valid branch" do
        before(:all) do
          @normal_repo = Gitlab::Git::Repository.new('default', TEST_NORMAL_REPO_PATH)
          @normal_repo.rugged.branches.create("feature", "origin/feature")
          @normal_repo.checkout("feature")
        end

        it "should move the HEAD to the correct commit" do
          expect(@normal_repo.rugged.head.target.oid).to(
            eq(@normal_repo.rugged.branches["feature"].target.oid)
          )
        end

        it "should update the working directory" do
          File.open(File.join(SEED_STORAGE_PATH, TEST_NORMAL_REPO_PATH, ".gitignore"), "r") do |f|
            expect(f.read.each_line.to_a).not_to include(".DS_Store\n")
          end
        end

        after(:all) do
          FileUtils.rm_rf(SEED_STORAGE_PATH, TEST_NORMAL_REPO_PATH)
          ensure_seeds
        end
      end
    end
  end

  describe "#delete_branch" do
    before(:all) do
      @repo = Gitlab::Git::Repository.new('default', TEST_MUTABLE_REPO_PATH)
      @repo.delete_branch("feature")
    end

    it "should remove the branch from the repo" do
      expect(@repo.rugged.branches["feature"]).to be_nil
    end

    it "should update the repo's #heads collection" do
      expect(@repo.heads).not_to include("feature")
    end

    after(:all) do
      FileUtils.rm_rf(TEST_MUTABLE_REPO_PATH)
      ensure_seeds
    end
  end

  describe "#create_branch" do
    before(:all) do
      @repo = Gitlab::Git::Repository.new('default', TEST_MUTABLE_REPO_PATH)
    end

    it "should create a new branch" do
      expect(@repo.create_branch('new_branch', 'master')).not_to be_nil
    end

    it "should create a new branch with the right name" do
      expect(@repo.create_branch('another_branch', 'master').name).to eq('another_branch')
    end

    it "should fail if we create an existing branch" do
      @repo.create_branch('duplicated_branch', 'master')
      expect{@repo.create_branch('duplicated_branch', 'master')}.to raise_error("Branch duplicated_branch already exists")
    end

    it "should fail if we create a branch from a non existing ref" do
      expect{@repo.create_branch('branch_based_in_wrong_ref', 'master_2_the_revenge')}.to raise_error("Invalid reference master_2_the_revenge")
    end

    after(:all) do
      FileUtils.rm_rf(TEST_MUTABLE_REPO_PATH)
      ensure_seeds
    end
  end

  describe "#remote_names" do
    let(:remotes) { repository.remote_names }

    it "should have one entry: 'origin'" do
      expect(remotes.size).to eq(1)
      expect(remotes.first).to eq("origin")
    end
  end

  describe "#refs_hash" do
    let(:refs) { repository.refs_hash }

    it "should have as many entries as branches and tags" do
      expected_refs = SeedRepo::Repo::BRANCHES + SeedRepo::Repo::TAGS
      # We flatten in case a commit is pointed at by more than one branch and/or tag
      expect(refs.values.flatten.size).to eq(expected_refs.size)
    end
  end

  describe "#remote_delete" do
    before(:all) do
      @repo = Gitlab::Git::Repository.new('default', TEST_MUTABLE_REPO_PATH)
      @repo.remote_delete("expendable")
    end

    it "should remove the remote" do
      expect(@repo.rugged.remotes).not_to include("expendable")
    end

    after(:all) do
      FileUtils.rm_rf(TEST_MUTABLE_REPO_PATH)
      ensure_seeds
    end
  end

  describe "#remote_add" do
    before(:all) do
      @repo = Gitlab::Git::Repository.new('default', TEST_MUTABLE_REPO_PATH)
      @repo.remote_add("new_remote", SeedHelper::GITLAB_GIT_TEST_REPO_URL)
    end

    it "should add the remote" do
      expect(@repo.rugged.remotes.each_name.to_a).to include("new_remote")
    end

    after(:all) do
      FileUtils.rm_rf(TEST_MUTABLE_REPO_PATH)
      ensure_seeds
    end
  end

  describe "#remote_update" do
    before(:all) do
      @repo = Gitlab::Git::Repository.new('default', TEST_MUTABLE_REPO_PATH)
      @repo.remote_update("expendable", url: TEST_NORMAL_REPO_PATH)
    end

    it "should add the remote" do
      expect(@repo.rugged.remotes["expendable"].url).to(
        eq(TEST_NORMAL_REPO_PATH)
      )
    end

    after(:all) do
      FileUtils.rm_rf(TEST_MUTABLE_REPO_PATH)
      ensure_seeds
    end
  end

  describe "#log" do
    commit_with_old_name = nil
    commit_with_new_name = nil
    rename_commit = nil

    before(:context) do
      # Add new commits so that there's a renamed file in the commit history
      repo = Gitlab::Git::Repository.new('default', TEST_REPO_PATH).rugged

      commit_with_old_name = new_commit_edit_old_file(repo)
      rename_commit = new_commit_move_file(repo)
      commit_with_new_name = new_commit_edit_new_file(repo)
    end

    after(:context) do
      # Erase our commits so other tests get the original repo
      repo = Gitlab::Git::Repository.new('default', TEST_REPO_PATH).rugged
      repo.references.update("refs/heads/master", SeedRepo::LastCommit::ID)
    end

    context "where 'follow' == true" do
      let(:options) { { ref: "master", follow: true } }

      context "and 'path' is a directory" do
        it "does not follow renames" do
          log_commits = repository.log(options.merge(path: "encoding"))

          aggregate_failures do
            expect(log_commits).to include(commit_with_new_name)
            expect(log_commits).to include(rename_commit)
            expect(log_commits).not_to include(commit_with_old_name)
          end
        end
      end

      context "and 'path' is a file that matches the new filename" do
        context 'without offset' do
          it "follows renames" do
            log_commits = repository.log(options.merge(path: "encoding/CHANGELOG"))

            aggregate_failures do
              expect(log_commits).to include(commit_with_new_name)
              expect(log_commits).to include(rename_commit)
              expect(log_commits).to include(commit_with_old_name)
            end
          end
        end

        context 'with offset=1' do
          it "follows renames and skip the latest commit" do
            log_commits = repository.log(options.merge(path: "encoding/CHANGELOG", offset: 1))

            aggregate_failures do
              expect(log_commits).not_to include(commit_with_new_name)
              expect(log_commits).to include(rename_commit)
              expect(log_commits).to include(commit_with_old_name)
            end
          end
        end

        context 'with offset=1', 'and limit=1' do
          it "follows renames, skip the latest commit and return only one commit" do
            log_commits = repository.log(options.merge(path: "encoding/CHANGELOG", offset: 1, limit: 1))

            expect(log_commits).to contain_exactly(rename_commit)
          end
        end

        context 'with offset=1', 'and limit=2' do
          it "follows renames, skip the latest commit and return only two commits" do
            log_commits = repository.log(options.merge(path: "encoding/CHANGELOG", offset: 1, limit: 2))

            aggregate_failures do
              expect(log_commits).to contain_exactly(rename_commit, commit_with_old_name)
            end
          end
        end

        context 'with offset=2' do
          it "follows renames and skip the latest commit" do
            log_commits = repository.log(options.merge(path: "encoding/CHANGELOG", offset: 2))

            aggregate_failures do
              expect(log_commits).not_to include(commit_with_new_name)
              expect(log_commits).not_to include(rename_commit)
              expect(log_commits).to include(commit_with_old_name)
            end
          end
        end

        context 'with offset=2', 'and limit=1' do
          it "follows renames, skip the two latest commit and return only one commit" do
            log_commits = repository.log(options.merge(path: "encoding/CHANGELOG", offset: 2, limit: 1))

            expect(log_commits).to contain_exactly(commit_with_old_name)
          end
        end

        context 'with offset=2', 'and limit=2' do
          it "follows renames, skip the two latest commit and return only one commit" do
            log_commits = repository.log(options.merge(path: "encoding/CHANGELOG", offset: 2, limit: 2))

            aggregate_failures do
              expect(log_commits).not_to include(commit_with_new_name)
              expect(log_commits).not_to include(rename_commit)
              expect(log_commits).to include(commit_with_old_name)
            end
          end
        end
      end

      context "and 'path' is a file that matches the old filename" do
        it "does not follow renames" do
          log_commits = repository.log(options.merge(path: "CHANGELOG"))

          aggregate_failures do
            expect(log_commits).not_to include(commit_with_new_name)
            expect(log_commits).to include(rename_commit)
            expect(log_commits).to include(commit_with_old_name)
          end
        end
      end

      context "unknown ref" do
        it "returns an empty array" do
          log_commits = repository.log(options.merge(ref: 'unknown'))

          expect(log_commits).to eq([])
        end
      end
    end

    context "where 'follow' == false" do
      options = { follow: false }

      context "and 'path' is a directory" do
        let(:log_commits) do
          repository.log(options.merge(path: "encoding"))
        end

        it "should not follow renames" do
          expect(log_commits).to include(commit_with_new_name)
          expect(log_commits).to include(rename_commit)
          expect(log_commits).not_to include(commit_with_old_name)
        end
      end

      context "and 'path' is a file that matches the new filename" do
        let(:log_commits) do
          repository.log(options.merge(path: "encoding/CHANGELOG"))
        end

        it "should not follow renames" do
          expect(log_commits).to include(commit_with_new_name)
          expect(log_commits).to include(rename_commit)
          expect(log_commits).not_to include(commit_with_old_name)
        end
      end

      context "and 'path' is a file that matches the old filename" do
        let(:log_commits) do
          repository.log(options.merge(path: "CHANGELOG"))
        end

        it "should not follow renames" do
          expect(log_commits).to include(commit_with_old_name)
          expect(log_commits).to include(rename_commit)
          expect(log_commits).not_to include(commit_with_new_name)
        end
      end

      context "and 'path' includes a directory that used to be a file" do
        let(:log_commits) do
          repository.log(options.merge(ref: "refs/heads/fix-blob-path", path: "files/testdir/file.txt"))
        end

        it "should return a list of commits" do
          expect(log_commits.size).to eq(1)
        end
      end
    end

    context "compare results between log_by_walk and log_by_shell" do
      let(:options) { { ref: "master" } }
      let(:commits_by_walk) { repository.log(options).map(&:oid) }
      let(:commits_by_shell) { repository.log(options.merge({ disable_walk: true })).map(&:oid) }

      it { expect(commits_by_walk).to eq(commits_by_shell) }

      context "with limit" do
        let(:options) { { ref: "master", limit: 1 } }

        it { expect(commits_by_walk).to eq(commits_by_shell) }
      end

      context "with offset" do
        let(:options) { { ref: "master", offset: 1 } }

        it { expect(commits_by_walk).to eq(commits_by_shell) }
      end

      context "with skip_merges" do
        let(:options) { { ref: "master", skip_merges: true } }

        it { expect(commits_by_walk).to eq(commits_by_shell) }
      end

      context "with path" do
        let(:options) { { ref: "master", path: "encoding" } }

        it { expect(commits_by_walk).to eq(commits_by_shell) }

        context "with follow" do
          let(:options) { { ref: "master", path: "encoding", follow: true } }

          it { expect(commits_by_walk).to eq(commits_by_shell) }
        end
      end
    end

    context "where provides 'after' timestamp" do
      options = { after: Time.iso8601('2014-03-03T20:15:01+00:00') }

      it "should returns commits on or after that timestamp" do
        commits = repository.log(options)

        expect(commits.size).to be > 0
        expect(commits).to satisfy do |commits|
          commits.all? { |commit| commit.time >= options[:after] }
        end
      end
    end

    context "where provides 'before' timestamp" do
      options = { before: Time.iso8601('2014-03-03T20:15:01+00:00') }

      it "should returns commits on or before that timestamp" do
        commits = repository.log(options)

        expect(commits.size).to be > 0
        expect(commits).to satisfy do |commits|
          commits.all? { |commit| commit.time <= options[:before] }
        end
      end
    end

    context 'when multiple paths are provided' do
      let(:options) { { ref: 'master', path: ['PROCESS.md', 'README.md'] } }

      def commit_files(commit)
        commit.diff(commit.parent_ids.first).deltas.flat_map do |delta|
          [delta.old_file[:path], delta.new_file[:path]].uniq.compact
        end
      end

      it 'only returns commits matching at least one path' do
        commits = repository.log(options)

        expect(commits.size).to be > 0
        expect(commits).to satisfy do |commits|
          commits.none? { |commit| (commit_files(commit) & options[:path]).empty? }
        end
      end
    end
  end

  describe "#commits_between" do
    context 'two SHAs' do
      let(:first_sha) { 'b0e52af38d7ea43cf41d8a6f2471351ac036d6c9' }
      let(:second_sha) { '0e50ec4d3c7ce42ab74dda1d422cb2cbffe1e326' }

      it 'returns the number of commits between' do
        expect(repository.commits_between(first_sha, second_sha).count).to eq(3)
      end
    end

    context 'SHA and master branch' do
      let(:sha) { 'b0e52af38d7ea43cf41d8a6f2471351ac036d6c9' }
      let(:branch) { 'master' }

      it 'returns the number of commits between a sha and a branch' do
        expect(repository.commits_between(sha, branch).count).to eq(5)
      end

      it 'returns the number of commits between a branch and a sha' do
        expect(repository.commits_between(branch, sha).count).to eq(0) # sha is before branch
      end
    end

    context 'two branches' do
      let(:first_branch) { 'feature' }
      let(:second_branch) { 'master' }

      it 'returns the number of commits between' do
        expect(repository.commits_between(first_branch, second_branch).count).to eq(17)
      end
    end
  end

  describe '#count_commits_between' do
    subject { repository.count_commits_between('feature', 'master') }

    it { is_expected.to eq(17) }
  end

  describe '#count_commits' do
    context 'with after timestamp' do
      it 'returns the number of commits after timestamp' do
        options = { ref: 'master', limit: nil, after: Time.iso8601('2013-03-03T20:15:01+00:00') }

        expect(repository.count_commits(options)).to eq(25)
      end
    end

    context 'with before timestamp' do
      it 'returns the number of commits after timestamp' do
        options = { ref: 'feature', limit: nil, before: Time.iso8601('2015-03-03T20:15:01+00:00') }

        expect(repository.count_commits(options)).to eq(9)
      end
    end

    context 'with path' do
      it 'returns the number of commits with path ' do
        options = { ref: 'master', limit: nil, path: "encoding" }

        expect(repository.count_commits(options)).to eq(2)
      end
    end
  end

  describe "branch_names_contains" do
    subject { repository.branch_names_contains(SeedRepo::LastCommit::ID) }

    it { is_expected.to include('master') }
    it { is_expected.not_to include('feature') }
    it { is_expected.not_to include('fix') }
  end

  describe '#autocrlf' do
    before(:all) do
      @repo = Gitlab::Git::Repository.new('default', TEST_MUTABLE_REPO_PATH)
      @repo.rugged.config['core.autocrlf'] = true
    end

    it 'return the value of the autocrlf option' do
      expect(@repo.autocrlf).to be(true)
    end

    after(:all) do
      @repo.rugged.config.delete('core.autocrlf')
    end
  end

  describe '#autocrlf=' do
    before(:all) do
      @repo = Gitlab::Git::Repository.new('default', TEST_MUTABLE_REPO_PATH)
      @repo.rugged.config['core.autocrlf'] = false
    end

    it 'should set the autocrlf option to the provided option' do
      @repo.autocrlf = :input

      File.open(File.join(SEED_STORAGE_PATH, TEST_MUTABLE_REPO_PATH, '.git', 'config')) do |config_file|
        expect(config_file.read).to match('autocrlf = input')
      end
    end

    after(:all) do
      @repo.rugged.config.delete('core.autocrlf')
    end
  end

  describe '#find_branch' do
    it 'should return a Branch for master' do
      branch = repository.find_branch('master')

      expect(branch).to be_a_kind_of(Gitlab::Git::Branch)
      expect(branch.name).to eq('master')
    end

    it 'should handle non-existent branch' do
      branch = repository.find_branch('this-is-garbage')

      expect(branch).to eq(nil)
    end

    it 'should reload Rugged::Repository and return master' do
      expect(Rugged::Repository).to receive(:new).twice.and_call_original

      repository.find_branch('master')
      branch = repository.find_branch('master', force_reload: true)

      expect(branch).to be_a_kind_of(Gitlab::Git::Branch)
      expect(branch.name).to eq('master')
    end
  end

  describe '#branches with deleted branch' do
    before(:each) do
      ref = double()
      allow(ref).to receive(:name) { 'bad-branch' }
      allow(ref).to receive(:target) { raise Rugged::ReferenceError }
      allow(repository.rugged).to receive(:branches) { [ref] }
    end

    it 'should return empty branches' do
      expect(repository.branches).to eq([])
    end
  end

  describe '#branch_count' do
    before(:each) do
      valid_ref   = double(:ref)
      invalid_ref = double(:ref)

      allow(valid_ref).to receive_messages(name: 'master', target: double(:target))

      allow(invalid_ref).to receive_messages(name: 'bad-branch')
      allow(invalid_ref).to receive(:target) { raise Rugged::ReferenceError }

      allow(repository.rugged).to receive_messages(branches: [valid_ref, invalid_ref])
    end

    it 'returns the number of branches' do
      expect(repository.branch_count).to eq(1)
    end
  end

  describe "#ls_files" do
    let(:master_file_paths) { repository.ls_files("master") }
    let(:not_existed_branch) { repository.ls_files("not_existed_branch") }

    it "read every file paths of master branch" do
      expect(master_file_paths.length).to equal(40)
    end

    it "reads full file paths of master branch" do
      expect(master_file_paths).to include("files/html/500.html")
    end

    it "dose not read submodule directory and empty directory of master branch" do
      expect(master_file_paths).not_to include("six")
    end

    it "does not include 'nil'" do
      expect(master_file_paths).not_to include(nil)
    end

    it "returns empty array when not existed branch" do
      expect(not_existed_branch.length).to equal(0)
    end
  end

  describe "#copy_gitattributes" do
    let(:attributes_path) { File.join(SEED_STORAGE_PATH, TEST_REPO_PATH, 'info/attributes') }

    it "raises an error with invalid ref" do
      expect { repository.copy_gitattributes("invalid") }.to raise_error(Gitlab::Git::Repository::InvalidRef)
    end

    context "with no .gitattrbutes" do
      before(:each) do
        repository.copy_gitattributes("master")
      end

      it "does not have an info/attributes" do
        expect(File.exist?(attributes_path)).to be_falsey
      end

      after(:each) do
        FileUtils.rm_rf(attributes_path)
      end
    end

    context "with .gitattrbutes" do
      before(:each) do
        repository.copy_gitattributes("gitattributes")
      end

      it "has an info/attributes" do
        expect(File.exist?(attributes_path)).to be_truthy
      end

      it "has the same content in info/attributes as .gitattributes" do
        contents = File.open(attributes_path, "rb") { |f| f.read }
        expect(contents).to eq("*.md binary\n")
      end

      after(:each) do
        FileUtils.rm_rf(attributes_path)
      end
    end

    context "with updated .gitattrbutes" do
      before(:each) do
        repository.copy_gitattributes("gitattributes")
        repository.copy_gitattributes("gitattributes-updated")
      end

      it "has an info/attributes" do
        expect(File.exist?(attributes_path)).to be_truthy
      end

      it "has the updated content in info/attributes" do
        contents = File.read(attributes_path)
        expect(contents).to eq("*.txt binary\n")
      end

      after(:each) do
        FileUtils.rm_rf(attributes_path)
      end
    end

    context "with no .gitattrbutes in HEAD but with previous info/attributes" do
      before(:each) do
        repository.copy_gitattributes("gitattributes")
        repository.copy_gitattributes("master")
      end

      it "does not have an info/attributes" do
        expect(File.exist?(attributes_path)).to be_falsey
      end

      after(:each) do
        FileUtils.rm_rf(attributes_path)
      end
    end
  end

  describe '#diffable' do
    info_dir_path = attributes_path = File.join(SEED_STORAGE_PATH, TEST_REPO_PATH, 'info')
    attributes_path = File.join(info_dir_path, 'attributes')

    before(:all) do
      FileUtils.mkdir(info_dir_path) unless File.exist?(info_dir_path)
      File.write(attributes_path, "*.md -diff\n")
    end

    it "should return true for files which are text and do not have attributes" do
      blob = Gitlab::Git::Blob.find(
        repository,
        '33bcff41c232a11727ac6d660bd4b0c2ba86d63d',
        'LICENSE'
      )
      expect(repository.diffable?(blob)).to be_truthy
    end

    it "should return false for binary files which do not have attributes" do
      blob = Gitlab::Git::Blob.find(
        repository,
        '33bcff41c232a11727ac6d660bd4b0c2ba86d63d',
        'files/images/logo-white.png'
      )
      expect(repository.diffable?(blob)).to be_falsey
    end

    it "should return false for text files which have been marked as not being diffable in attributes" do
      blob = Gitlab::Git::Blob.find(
        repository,
        '33bcff41c232a11727ac6d660bd4b0c2ba86d63d',
        'README.md'
      )
      expect(repository.diffable?(blob)).to be_falsey
    end

    after(:all) do
      FileUtils.rm_rf(info_dir_path)
    end
  end

  describe '#tag_exists?' do
    it 'returns true for an existing tag' do
      tag = repository.tag_names.first

      expect(repository.tag_exists?(tag)).to eq(true)
    end

    it 'returns false for a non-existing tag' do
      expect(repository.tag_exists?('v9000')).to eq(false)
    end
  end

  describe '#branch_exists?' do
    it 'returns true for an existing branch' do
      expect(repository.branch_exists?('master')).to eq(true)
    end

    it 'returns false for a non-existing branch' do
      expect(repository.branch_exists?('kittens')).to eq(false)
    end

    it 'returns false when using an invalid branch name' do
      expect(repository.branch_exists?('.bla')).to eq(false)
    end
  end

  describe '#local_branches' do
    before(:all) do
      @repo = Gitlab::Git::Repository.new('default', TEST_MUTABLE_REPO_PATH)
    end

    after(:all) do
      FileUtils.rm_rf(TEST_MUTABLE_REPO_PATH)
      ensure_seeds
    end

    it 'returns the local branches' do
      create_remote_branch('joe', 'remote_branch', 'master')
      @repo.create_branch('local_branch', 'master')

      expect(@repo.local_branches.any? { |branch| branch.name == 'remote_branch' }).to eq(false)
      expect(@repo.local_branches.any? { |branch| branch.name == 'local_branch' }).to eq(true)
    end
  end

  def create_remote_branch(remote_name, branch_name, source_branch_name)
    source_branch = @repo.branches.find { |branch| branch.name == source_branch_name }
    rugged = @repo.rugged
    rugged.references.create("refs/remotes/#{remote_name}/#{branch_name}", source_branch.dereferenced_target.sha)
  end

  # Build the options hash that's passed to Rugged::Commit#create
  def commit_options(repo, index, message)
    options = {}
    options[:tree] = index.write_tree(repo)
    options[:author] = {
      email: "test@example.com",
      name: "Test Author",
      time: Time.gm(2014, "mar", 3, 20, 15, 1)
    }
    options[:committer] = {
      email: "test@example.com",
      name: "Test Author",
      time: Time.gm(2014, "mar", 3, 20, 15, 1)
    }
    options[:message] ||= message
    options[:parents] = repo.empty? ? [] : [repo.head.target].compact
    options[:update_ref] = "HEAD"

    options
  end

  # Writes a new commit to the repo and returns a Rugged::Commit.  Replaces the
  # contents of CHANGELOG with a single new line of text.
  def new_commit_edit_old_file(repo)
    oid = repo.write("I replaced the changelog with this text", :blob)
    index = repo.index
    index.read_tree(repo.head.target.tree)
    index.add(path: "CHANGELOG", oid: oid, mode: 0100644)

    options = commit_options(
      repo,
      index,
      "Edit CHANGELOG in its original location"
    )

    sha = Rugged::Commit.create(repo, options)
    repo.lookup(sha)
  end

  # Writes a new commit to the repo and returns a Rugged::Commit.  Replaces the
  # contents of encoding/CHANGELOG with new text.
  def new_commit_edit_new_file(repo)
    oid = repo.write("I'm a new changelog with different text", :blob)
    index = repo.index
    index.read_tree(repo.head.target.tree)
    index.add(path: "encoding/CHANGELOG", oid: oid, mode: 0100644)

    options = commit_options(repo, index, "Edit encoding/CHANGELOG")

    sha = Rugged::Commit.create(repo, options)
    repo.lookup(sha)
  end

  # Writes a new commit to the repo and returns a Rugged::Commit.  Moves the
  # CHANGELOG file to the encoding/ directory.
  def new_commit_move_file(repo)
    blob_oid = repo.head.target.tree.detect { |i| i[:name] == "CHANGELOG" }[:oid]
    file_content = repo.lookup(blob_oid).content
    oid = repo.write(file_content, :blob)
    index = repo.index
    index.read_tree(repo.head.target.tree)
    index.add(path: "encoding/CHANGELOG", oid: oid, mode: 0100644)
    index.remove("CHANGELOG")

    options = commit_options(repo, index, "Move CHANGELOG to encoding/")

    sha = Rugged::Commit.create(repo, options)
    repo.lookup(sha)
  end

  def stub_gitaly
    allow(Gitlab::GitalyClient).to receive(:feature_enabled?).and_return(true)

    stub = double(:stub)
    allow(Gitaly::Ref::Stub).to receive(:new).and_return(stub)
  end
end
