require 'spec_helper'

feature 'Admin Groups', feature: true do
  include Select2Helper

  let(:internal) { Gitlab::VisibilityLevel::INTERNAL }
  let(:user) { create :user }
  let!(:group) { create :group }
  let!(:current_user) { login_as :admin }

  before do
    stub_application_setting(default_group_visibility: internal)
  end

  describe 'list' do
    it 'renders groups' do
      visit admin_groups_path

      expect(page).to have_content(group.name)
    end
  end

  describe 'create a group' do
    it 'creates new group' do
      visit admin_groups_path

      click_link "New group"
      fill_in 'group_path', with: 'gitlab'
      fill_in 'group_description', with: 'Group description'
      click_button "Create group"

      expect(current_path).to eq admin_group_path(Group.find_by(path: 'gitlab'))
      expect(page).to have_content('Group: gitlab')
      expect(page).to have_content('Group description')
    end

    scenario 'shows the visibility level radio populated with the default value' do
      visit new_admin_group_path

      expect_selected_visibility(internal)
    end
  end

  describe 'show a group' do
    scenario 'shows the group' do
      group = create(:group, :private)

      visit admin_group_path(group)

      expect(page).to have_content("Group: #{group.name}")
    end
  end

  describe 'group edit' do
    scenario 'shows the visibility level radio populated with the group visibility_level value' do
      group = create(:group, :private)

      visit admin_group_edit_path(group)

      expect_selected_visibility(group.visibility_level)
    end
  end

  describe 'add user into a group', js: true do
    shared_context 'adds user into a group' do
      it do
        visit admin_group_path(group)

        select2(user_selector, from: '#user_ids', multiple: true)
        page.within '#new_project_member' do
          select2(Gitlab::Access::REPORTER, from: '#access_level')
        end
        click_button "Add users to group"
        page.within ".group-users-list" do
          expect(page).to have_content(user.name)
          expect(page).to have_content('Reporter')
        end
      end
    end

    it_behaves_like 'adds user into a group' do
      let(:user_selector) { user.id }
    end

    it_behaves_like 'adds user into a group' do
      let(:user_selector) { user.email }
    end
  end

  describe 'add admin himself to a group' do
    before do
      group.add_user(:user, Gitlab::Access::OWNER)
    end

    it 'adds admin a to a group as developer', js: true do
      visit group_group_members_path(group)

      page.within '.users-group-form' do
        select2(current_user.id, from: '#user_ids', multiple: true)
        select 'Developer', from: 'access_level'
      end

      click_button 'Add to group'

      page.within '.content-list' do
        expect(page).to have_content(current_user.name)
        expect(page).to have_content('Developer')
      end
    end
  end

  describe 'admin remove himself from a group', js: true do
    it 'removes admin from the group' do
      group.add_user(current_user, Gitlab::Access::DEVELOPER)

      visit group_group_members_path(group)

      page.within '.content-list' do
        expect(page).to have_content(current_user.name)
        expect(page).to have_content('Developer')
      end

      find(:css, 'li', text: current_user.name).find(:css, 'a.btn-remove').click

      visit group_group_members_path(group)

      page.within '.content-list' do
        expect(page).not_to have_content(current_user.name)
        expect(page).not_to have_content('Developer')
      end
    end
  end

  describe 'shared projects' do
    it 'renders shared project' do
      empty_project = create(:empty_project)
      empty_project.project_group_links.create!(
        group_access: Gitlab::Access::MASTER,
        group: group
      )

      visit admin_group_path(group)

      expect(page).to have_content(empty_project.name_with_namespace)
      expect(page).to have_content('Projects shared with')
    end
  end

  def expect_selected_visibility(level)
    selector = "#group_visibility_level_#{level}[checked=checked]"

    expect(page).to have_selector(selector, count: 1)
  end
end
