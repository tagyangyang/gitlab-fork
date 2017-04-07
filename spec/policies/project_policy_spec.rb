require 'spec_helper'

describe ProjectPolicy, models: true do
  let(:guest) { create(:user) }
  let(:reporter) { create(:user) }
  let(:dev) { create(:user) }
  let(:master) { create(:user) }
  let(:owner) { create(:user) }
  let(:admin) { create(:admin) }
  let(:project) { create(:empty_project, :public, namespace: owner.namespace) }

  let(:guest_permissions) do
    %i[
      read_project read_board read_list read_wiki read_issue read_label
      read_milestone read_project_snippet read_project_member
      read_note create_project create_issue create_note
      upload_file
    ]
  end

  let(:reporter_permissions) do
    %i[
      download_code fork_project create_project_snippet update_issue
      admin_issue admin_label admin_list read_commit_status read_build
      read_container_image read_pipeline read_environment read_deployment
      read_merge_request download_wiki_code
    ]
  end

  let(:team_member_reporter_permissions) do
    %i[build_download_code build_read_container_image]
  end

  let(:developer_permissions) do
    %i[
      admin_merge_request update_merge_request create_commit_status
      update_commit_status create_build update_build create_pipeline
      update_pipeline create_merge_request create_wiki push_code
      resolve_note create_container_image update_container_image
      create_environment create_deployment
    ]
  end

  let(:master_permissions) do
    %i[
      push_code_to_protected_branches update_project_snippet update_environment
      update_deployment admin_milestone admin_project_snippet
      admin_project_member admin_note admin_wiki admin_project
      admin_commit_status admin_build admin_container_image
      admin_pipeline admin_environment admin_deployment
    ]
  end

  let(:public_permissions) do
    %i[
      download_code fork_project read_commit_status read_pipeline
      read_container_image build_download_code build_read_container_image
      download_wiki_code
    ]
  end

  let(:owner_permissions) do
    %i[
      change_namespace change_visibility_level rename_project remove_project
      archive_project remove_fork_project destroy_merge_request destroy_issue
    ]
  end

  before do
    project.team << [guest, :guest]
    project.team << [master, :master]
    project.team << [dev, :developer]
    project.team << [reporter, :reporter]
  end

  def expect_allowed(*permissions)
    permissions.each { |p| is_expected.to be_allowed(p) }
  end

  def expect_disallowed(*permissions)
    permissions.each { |p| is_expected.not_to be_allowed(p) }
  end

  it 'does not include the read_issue permission when the issue author is not a member of the private project' do
    project = create(:empty_project, :private)
    issue   = create(:issue, project: project)
    user    = issue.author

    expect(project.team.member?(issue.author)).to be false

    expect(Ability).not_to be_allowed(user, :read_issue, project)
  end

  context 'when the feature is disabled' do
    subject { described_class.new(owner, project) }

    before do
      project.project_feature.update_attribute(:wiki_access_level, ProjectFeature::DISABLED)
    end

    it 'does not include the wiki permissions' do
      expect_disallowed :read_wiki, :create_wiki, :update_wiki, :admin_wiki, :download_wiki_code
    end
  end

  context 'abilities for non-public projects' do
    let(:project) { create(:empty_project, namespace: owner.namespace) }

    subject { described_class.new(current_user, project) }

    context 'with no user' do
      let(:current_user) { nil }

      it { is_expected.to be_banned }
    end

    context 'guests' do
      let(:current_user) { guest }

      let(:reporter_public_build_permissions) do
        reporter_permissions - [:read_build, :read_pipeline]
      end

      it do
        expect_allowed(*guest_permissions)
        expect_disallowed(*reporter_public_build_permissions)
        expect_disallowed(*team_member_reporter_permissions)
        expect_disallowed(*developer_permissions)
        expect_disallowed(*master_permissions)
        expect_disallowed(*owner_permissions)
      end

      context 'public builds enabled' do
        it do
          expect_allowed(*guest_permissions)
          expect_allowed(:read_build, :read_pipeline)
        end
      end

      context 'public builds disabled' do
        before do
          project.update(public_builds: false)
        end

        it do
          expect_allowed(*guest_permissions)
          expect_disallowed(:read_build, :read_pipeline)
        end
      end
    end

    context 'reporter' do
      let(:current_user) { reporter }

      it do
        expect_allowed *guest_permissions
        expect_allowed *reporter_permissions
        expect_allowed *reporter_permissions
        expect_allowed *team_member_reporter_permissions
        expect_disallowed *developer_permissions
        expect_disallowed *master_permissions
        expect_disallowed *owner_permissions
      end
    end

    context 'developer' do
      let(:current_user) { dev }

      it do
        expect_allowed(*guest_permissions)
        expect_allowed(*reporter_permissions)
        expect_allowed(*team_member_reporter_permissions)
        expect_allowed(*developer_permissions)
        expect_disallowed(*master_permissions)
        expect_disallowed(*owner_permissions)
      end
    end

    context 'master' do
      let(:current_user) { master }

      it do
        expect_allowed(*guest_permissions)
        expect_allowed(*reporter_permissions)
        expect_allowed(*team_member_reporter_permissions)
        expect_allowed(*developer_permissions)
        expect_allowed(*master_permissions)
        expect_disallowed(*owner_permissions)
      end
    end

    context 'owner' do
      let(:current_user) { owner }

      it do
        expect_allowed(*guest_permissions)
        expect_allowed(*reporter_permissions)
        expect_allowed(*team_member_reporter_permissions)
        expect_allowed(*developer_permissions)
        expect_allowed(*master_permissions)
        expect_allowed(*owner_permissions)
      end
    end

    context 'admin' do
      let(:current_user) { admin }

      it do
        expect_allowed(*guest_permissions)
        expect_allowed(*reporter_permissions)
        expect_disallowed(*team_member_reporter_permissions)
        expect_allowed(*developer_permissions)
        expect_allowed(*master_permissions)
        expect_allowed(*owner_permissions)
      end
    end
  end
end
