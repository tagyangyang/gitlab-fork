require 'spec_helper'

describe Gitlab::GitAccess, lib: true do
  let(:access) { Gitlab::GitAccess.new(actor, project, 'web', authentication_abilities: authentication_abilities) }
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }
  let(:actor) { user }
  let(:authentication_abilities) do
    [
      :read_project,
      :download_code,
      :push_code
    ]
  end

  describe '#check with single protocols allowed' do
    def disable_protocol(protocol)
      settings = ::ApplicationSetting.create_from_defaults
      settings.update_attribute(:enabled_git_access_protocol, protocol)
    end

    context 'ssh disabled' do
      before do
        disable_protocol('ssh')
        @acc = Gitlab::GitAccess.new(actor, project, 'ssh', authentication_abilities: authentication_abilities)
      end

      it 'blocks ssh git push' do
        expect(@acc.check('git-receive-pack', '_any').allowed?).to be_falsey
      end

      it 'blocks ssh git pull' do
        expect(@acc.check('git-upload-pack', '_any').allowed?).to be_falsey
      end
    end

    context 'http disabled' do
      before do
        disable_protocol('http')
        @acc = Gitlab::GitAccess.new(actor, project, 'http', authentication_abilities: authentication_abilities)
      end

      it 'blocks http push' do
        expect(@acc.check('git-receive-pack', '_any').allowed?).to be_falsey
      end

      it 'blocks http git pull' do
        expect(@acc.check('git-upload-pack', '_any').allowed?).to be_falsey
      end
    end
  end

  describe '#check_download_access!' do
    subject { access.check('git-upload-pack', '_any') }

    describe 'master permissions' do
      before { project.team << [user, :master] }

      context 'pull code' do
        it { expect(subject.allowed?).to be_truthy }
      end
    end

    describe 'guest permissions' do
      before { project.team << [user, :guest] }

      context 'pull code' do
        it { expect(subject.allowed?).to be_falsey }
        it { expect(subject.message).to match(/You are not allowed to download code/) }
      end
    end

    describe 'blocked user' do
      before do
        project.team << [user, :master]
        user.block
      end

      context 'pull code' do
        it { expect(subject.allowed?).to be_falsey }
        it { expect(subject.message).to match(/Your account has been blocked/) }
      end
    end

    describe 'without access to project' do
      context 'pull code' do
        it { expect(subject.allowed?).to be_falsey }
      end

      context 'when project is public' do
        let(:public_project) { create(:project, :public, :repository) }
        let(:guest_access) { Gitlab::GitAccess.new(nil, public_project, 'web', authentication_abilities: []) }
        subject { guest_access.check('git-upload-pack', '_any') }

        context 'when repository is enabled' do
          it 'give access to download code' do
            expect(subject.allowed?).to be_truthy
          end
        end

        context 'when repository is disabled' do
          it 'does not give access to download code' do
            public_project.project_feature.update_attribute(:repository_access_level, ProjectFeature::DISABLED)

            expect(subject.allowed?).to be_falsey
            expect(subject.message).to match(/You are not allowed to download code/)
          end
        end
      end
    end

    describe 'deploy key permissions' do
      let(:key) { create(:deploy_key, user: user) }
      let(:actor) { key }

      context 'pull code' do
        context 'when project is authorized' do
          before { key.projects << project }

          it { expect(subject).to be_allowed }
        end

        context 'when unauthorized' do
          context 'from public project' do
            let(:project) { create(:project, :public, :repository) }

            it { expect(subject).to be_allowed }
          end

          context 'from internal project' do
            let(:project) { create(:project, :internal, :repository) }

            it { expect(subject).not_to be_allowed }
          end

          context 'from private project' do
            let(:project) { create(:project, :private, :repository) }

            it { expect(subject).not_to be_allowed }
          end
        end
      end
    end

    describe 'build authentication_abilities permissions' do
      let(:authentication_abilities) { build_authentication_abilities }

      describe 'owner' do
        let(:project) { create(:project, :repository, namespace: user.namespace) }

        context 'pull code' do
          it { expect(subject).to be_allowed }
        end
      end

      describe 'reporter user' do
        before { project.team << [user, :reporter] }

        context 'pull code' do
          it { expect(subject).to be_allowed }
        end
      end

      describe 'admin user' do
        let(:user) { create(:admin) }

        context 'when member of the project' do
          before { project.team << [user, :reporter] }

          context 'pull code' do
            it { expect(subject).to be_allowed }
          end
        end

        context 'when is not member of the project' do
          context 'pull code' do
            it { expect(subject).not_to be_allowed }
          end
        end
      end
    end
  end

  describe '#check_push_access!' do
    before { merge_into_protected_branch }
    let(:unprotected_branch) { 'unprotected_branch' }

    let(:changes) do
      { push_new_branch: "#{Gitlab::Git::BLANK_SHA} 570e7b2ab refs/heads/wow",
        push_master: '6f6d7e7ed 570e7b2ab refs/heads/master',
        push_protected_branch: '6f6d7e7ed 570e7b2ab refs/heads/feature',
        push_remove_protected_branch: "570e7b2ab #{Gitlab::Git::BLANK_SHA} "\
                                      'refs/heads/feature',
        push_tag: '6f6d7e7ed 570e7b2ab refs/tags/v1.0.0',
        push_new_tag: "#{Gitlab::Git::BLANK_SHA} 570e7b2ab refs/tags/v7.8.9",
        push_all: ['6f6d7e7ed 570e7b2ab refs/heads/master', '6f6d7e7ed 570e7b2ab refs/heads/feature'],
        merge_into_protected_branch: "0b4bc9a #{merge_into_protected_branch} refs/heads/feature" }
    end

    def stub_git_hooks
      # Running the `pre-receive` hook is expensive, and not necessary for this test.
      allow_any_instance_of(GitHooksService).to receive(:execute) do |service, &block|
        block.call(service)
      end
    end

    def merge_into_protected_branch
      @protected_branch_merge_commit ||= begin
        stub_git_hooks
        project.repository.add_branch(user, unprotected_branch, 'feature')
        target_branch = project.repository.lookup('feature')
        source_branch = project.repository.create_file(
          user,
          'John Doe',
          'This is the file content',
          message: 'This is a good commit message',
          branch_name: unprotected_branch)
        rugged = project.repository.rugged
        author = { email: "email@example.com", time: Time.now, name: "Example Git User" }

        merge_index = rugged.merge_commits(target_branch, source_branch)
        Rugged::Commit.create(rugged, author: author, committer: author, message: "commit message", parents: [target_branch, source_branch], tree: merge_index.write_tree(rugged))
      end
    end

    # Run permission checks for a user
    def self.run_permission_checks(permissions_matrix)
      permissions_matrix.keys.each do |role|
        describe "#{role} access" do
          before do
            if role == :admin
              user.update_attribute(:admin, true)
            else
              project.team << [user, role]
            end
          end

          permissions_matrix[role].each do |action, allowed|
            context action do
              subject { access.send(:check_push_access!, changes[action]) }

              it do
                if allowed
                  expect { subject }.not_to raise_error
                else
                  expect { subject }.to raise_error(Gitlab::GitAccess::UnauthorizedError)
                end
              end
            end
          end
        end
      end
    end

    permissions_matrix = {
      admin: {
        push_new_branch: true,
        push_master: true,
        push_protected_branch: true,
        push_remove_protected_branch: false,
        push_tag: true,
        push_new_tag: true,
        push_all: true,
        merge_into_protected_branch: true
      },

      master: {
        push_new_branch: true,
        push_master: true,
        push_protected_branch: true,
        push_remove_protected_branch: false,
        push_tag: true,
        push_new_tag: true,
        push_all: true,
        merge_into_protected_branch: true
      },

      developer: {
        push_new_branch: true,
        push_master: true,
        push_protected_branch: false,
        push_remove_protected_branch: false,
        push_tag: false,
        push_new_tag: true,
        push_all: false,
        merge_into_protected_branch: false
      },

      reporter: {
        push_new_branch: false,
        push_master: false,
        push_protected_branch: false,
        push_remove_protected_branch: false,
        push_tag: false,
        push_new_tag: false,
        push_all: false,
        merge_into_protected_branch: false
      },

      guest: {
        push_new_branch: false,
        push_master: false,
        push_protected_branch: false,
        push_remove_protected_branch: false,
        push_tag: false,
        push_new_tag: false,
        push_all: false,
        merge_into_protected_branch: false
      }
    }

    [%w(feature exact), ['feat*', 'wildcard']].each do |protected_branch_name, protected_branch_type|
      context do
        before { create(:protected_branch, name: protected_branch_name, project: project) }

        run_permission_checks(permissions_matrix)
      end

      context "when developers are allowed to push into the #{protected_branch_type} protected branch" do
        before { create(:protected_branch, :developers_can_push, name: protected_branch_name, project: project) }

        run_permission_checks(permissions_matrix.deep_merge(developer: { push_protected_branch: true, push_all: true, merge_into_protected_branch: true }))
      end

      context "developers are allowed to merge into the #{protected_branch_type} protected branch" do
        before { create(:protected_branch, :developers_can_merge, name: protected_branch_name, project: project) }

        context "when a merge request exists for the given source/target branch" do
          context "when the merge request is in progress" do
            before do
              create(:merge_request, source_project: project, source_branch: unprotected_branch, target_branch: 'feature',
                                     state: 'locked', in_progress_merge_commit_sha: merge_into_protected_branch)
            end

            run_permission_checks(permissions_matrix.deep_merge(developer: { merge_into_protected_branch: true }))
          end

          context "when the merge request is not in progress" do
            before do
              create(:merge_request, source_project: project, source_branch: unprotected_branch, target_branch: 'feature', in_progress_merge_commit_sha: nil)
            end

            run_permission_checks(permissions_matrix.deep_merge(developer: { merge_into_protected_branch: false }))
          end

          context "when a merge request does not exist for the given source/target branch" do
            run_permission_checks(permissions_matrix.deep_merge(developer: { merge_into_protected_branch: false }))
          end
        end
      end

      context "when developers are allowed to push and merge into the #{protected_branch_type} protected branch" do
        before { create(:protected_branch, :developers_can_merge, :developers_can_push, name: protected_branch_name, project: project) }

        run_permission_checks(permissions_matrix.deep_merge(developer: { push_protected_branch: true, push_all: true, merge_into_protected_branch: true }))
      end

      context "when no one is allowed to push to the #{protected_branch_name} protected branch" do
        before { create(:protected_branch, :no_one_can_push, name: protected_branch_name, project: project) }

        run_permission_checks(permissions_matrix.deep_merge(developer: { push_protected_branch: false, push_all: false, merge_into_protected_branch: false },
                                                            master: { push_protected_branch: false, push_all: false, merge_into_protected_branch: false },
                                                            admin: { push_protected_branch: false, push_all: false, merge_into_protected_branch: false }))
      end
    end
  end

  shared_examples 'pushing code' do |can|
    subject { access.check('git-receive-pack', '_any') }

    context 'when project is authorized' do
      before { authorize }

      it { expect(subject).public_send(can, be_allowed) }
    end

    context 'when unauthorized' do
      context 'to public project' do
        let(:project) { create(:project, :public, :repository) }

        it { expect(subject).not_to be_allowed }
      end

      context 'to internal project' do
        let(:project) { create(:project, :internal, :repository) }

        it { expect(subject).not_to be_allowed }
      end

      context 'to private project' do
        let(:project) { create(:project, :private, :repository) }

        it { expect(subject).not_to be_allowed }
      end
    end
  end

  describe 'build authentication abilities' do
    let(:authentication_abilities) { build_authentication_abilities }

    it_behaves_like 'pushing code', :not_to do
      def authorize
        project.team << [user, :reporter]
      end
    end
  end

  describe 'deploy key permissions' do
    let(:key) { create(:deploy_key, user: user, can_push: can_push) }
    let(:actor) { key }

    context 'when deploy_key can push' do
      let(:can_push) { true }

      it_behaves_like 'pushing code', :to do
        def authorize
          key.projects << project
        end
      end
    end

    context 'when deploy_key cannot push' do
      let(:can_push) { false }

      it_behaves_like 'pushing code', :not_to do
        def authorize
          key.projects << project
        end
      end
    end
  end

  private

  def build_authentication_abilities
    [
      :read_project,
      :build_download_code
    ]
  end

  def full_authentication_abilities
    [
      :read_project,
      :download_code,
      :push_code
    ]
  end
end
