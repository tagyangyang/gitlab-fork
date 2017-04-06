require 'spec_helper'

describe GroupPolicy, models: true do
  let(:guest) { create(:user) }
  let(:reporter) { create(:user) }
  let(:developer) { create(:user) }
  let(:master) { create(:user) }
  let(:owner) { create(:user) }
  let(:admin) { create(:admin) }
  let(:group) { create(:group) }

  let(:master_permissions) do
    [
      :create_projects,
      :admin_milestones,
      :admin_label
    ]
  end

  let(:owner_permissions) do
    [
      :admin_group,
      :admin_namespace,
      :admin_group_member,
      :change_visibility_level
    ]
  end

  before do
    group.add_guest(guest)
    group.add_reporter(reporter)
    group.add_developer(developer)
    group.add_master(master)
    group.add_owner(owner)
  end

  subject { described_class.new(current_user, group) }

  def expect_allowed(*permissions)
    permissions.each { |p| is_expected.to be_allowed(p) }
  end

  def expect_disallowed(*permissions)
    permissions.each { |p| is_expected.not_to be_allowed(p) }
  end

  context 'with no user' do
    let(:current_user) { nil }

    it do
      expect_allowed(:read_group)
      expect_disallowed(*master_permissions)
      expect_disallowed(*owner_permissions)
    end
  end

  context 'guests' do
    let(:current_user) { guest }

    it do
      expect_allowed(:read_group)
      expect_disallowed(*master_permissions)
      expect_disallowed(*owner_permissions)
    end
  end

  context 'reporter' do
    let(:current_user) { reporter }

    it do
      expect_allowed(:read_group)
      expect_disallowed(*master_permissions)
      expect_disallowed(*owner_permissions)
    end
  end

  context 'developer' do
    let(:current_user) { developer }

    it do
      expect_allowed(:read_group)
      expect_disallowed(*master_permissions)
      expect_disallowed(*owner_permissions)
    end
  end

  context 'master' do
    let(:current_user) { master }

    it do
      expect_allowed(:read_group)
      expect_allowed(*master_permissions)
      expect_disallowed(*owner_permissions)
    end
  end

  context 'owner' do
    let(:current_user) { owner }

    it do
      expect_allowed(:read_group)
      expect_allowed(*master_permissions)
      expect_allowed(*owner_permissions)
    end
  end

  context 'admin' do
    let(:current_user) { admin }

    it do
      expect_allowed(:read_group)
      expect_allowed(*master_permissions)
      expect_allowed(*owner_permissions)
    end
  end

  describe 'private nested group inherit permissions' do
    let(:nested_group) { create(:group, :private, parent: group) }

    subject { described_class.new(current_user, nested_group) }

    context 'with no user' do
      let(:current_user) { nil }

      it do
        expect_disallowed(:read_group)
        expect_disallowed(*master_permissions)
        expect_disallowed(*owner_permissions)
      end
    end

    context 'guests' do
      let(:current_user) { guest }

      it do
        expect_allowed(:read_group)
        expect_disallowed(*master_permissions)
        expect_disallowed(*owner_permissions)
      end
    end

    context 'reporter' do
      let(:current_user) { reporter }

      it do
        expect_allowed(:read_group)
        expect_disallowed(*master_permissions)
        expect_disallowed(*owner_permissions)
      end
    end

    context 'developer' do
      let(:current_user) { developer }

      it do
        expect_allowed(:read_group)
        expect_disallowed(*master_permissions)
        expect_disallowed(*owner_permissions)
      end
    end

    context 'master' do
      let(:current_user) { master }

      it do
        expect_allowed(:read_group)
        expect_allowed(*master_permissions)
        expect_disallowed(*owner_permissions)
      end
    end

    context 'owner' do
      let(:current_user) { owner }

      it do
        expect_allowed(:read_group)
        expect_allowed(*master_permissions)
        expect_allowed(*owner_permissions)
      end
    end
  end
end
