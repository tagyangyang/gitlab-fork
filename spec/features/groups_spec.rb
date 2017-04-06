require 'spec_helper'

feature 'Group', feature: true do
  before do
    login_as(:admin)
  end

  matcher :have_namespace_error_message do
    match do |page|
      page.has_content?("Path can contain only letters, digits, '_', '-' and '.'. Cannot start with '-' or end in '.', '.git' or '.atom'.")
    end
  end

  describe 'create a group' do
    before { visit new_group_path }

    describe 'with space in group path' do
      it 'renders new group form with validation errors' do
        fill_in 'Group path', with: 'space group'
        click_button 'Create group'

        expect(current_path).to eq(groups_path)
        expect(page).to have_namespace_error_message
      end
    end

    describe 'with .atom at end of group path' do
      it 'renders new group form with validation errors' do
        fill_in 'Group path', with: 'atom_group.atom'
        click_button 'Create group'

        expect(current_path).to eq(groups_path)
        expect(page).to have_namespace_error_message
      end
    end

    describe 'with .git at end of group path' do
      it 'renders new group form with validation errors' do
        fill_in 'Group path', with: 'git_group.git'
        click_button 'Create group'

        expect(current_path).to eq(groups_path)
        expect(page).to have_namespace_error_message
      end
    end

    describe 'Mattermost team creation' do
      before do
        stub_mattermost_setting(enabled: mattermost_enabled)

        visit new_group_path
      end

      context 'Mattermost enabled' do
        let(:mattermost_enabled) { true }

        it 'displays a team creation checkbox' do
          expect(page).to have_selector('#group_create_chat_team')
        end

        it 'checks the checkbox by default' do
          expect(find('#group_create_chat_team')['checked']).to eq(true)
        end

        it 'updates the team URL on graph path update', :js do
          out_span = find('span[data-bind-out="create_chat_team"]')

          expect(out_span.text).to be_empty

          fill_in('group_path', with: 'test-group')

          expect(out_span.text).to eq('test-group')
        end
      end

      context 'Mattermost disabled' do
        let(:mattermost_enabled) { false }

        it 'doesnt show a team creation checkbox if Mattermost not enabled' do
          expect(page).not_to have_selector('#group_create_chat_team')
        end
      end
    end
  end

  describe 'create a nested group', js: true do
    let(:group) { create(:group, path: 'foo') }

    context 'as admin' do
      before do
        visit subgroups_group_path(group)
        click_link 'New Subgroup'
      end

      it 'creates a nested group' do
        fill_in 'Group path', with: 'bar'
        click_button 'Create group'

        expect(current_path).to eq(group_path('foo/bar'))
        expect(page).to have_content("Group 'bar' was successfully created.")
      end
    end

    context 'as group owner' do
      let(:user) { create(:user) }

      before do
        group.add_owner(user)
        logout
        login_as(user)

        visit subgroups_group_path(group)
        click_link 'New Subgroup'
      end

      it 'creates a nested group' do
        fill_in 'Group path', with: 'bar'
        click_button 'Create group'

        expect(current_path).to eq(group_path('foo/bar'))
        expect(page).to have_content("Group 'bar' was successfully created.")
      end
    end
  end

  it 'checks permissions to avoid exposing groups by parent_id' do
    group = create(:group, :private, path: 'secret-group')

    logout
    login_as(:user)
    visit new_group_path(parent_id: group.id)

    expect(page).not_to have_content('secret-group')
  end

  describe 'group edit' do
    let(:group) { create(:group) }
    let(:path)  { edit_group_path(group) }
    let(:new_name) { 'new-name' }

    before { visit path }

    it 'saves new settings' do
      fill_in 'group_name', with: new_name
      click_button 'Save group'

      expect(page).to have_content 'successfully updated'
      expect(find('#group_name').value).to eq(new_name)

      page.within ".navbar-gitlab" do
        expect(page).to have_content new_name
      end
    end

    it 'removes group' do
      click_link 'Remove Group'

      expect(page).to have_content "scheduled for deletion"
    end
  end

  describe 'group page with markdown description' do
    let(:group) { create(:group) }
    let(:path)  { group_path(group) }

    it 'parses Markdown' do
      group.update_attribute(:description, 'This is **my** group')

      visit path

      expect(page).to have_css('.group-home-desc > p > strong')
    end

    it 'passes through html-pipeline' do
      group.update_attribute(:description, 'This group is the :poop:')

      visit path

      expect(page).to have_css('.group-home-desc > p > gl-emoji')
    end

    it 'sanitizes unwanted tags' do
      group.update_attribute(:description, '# Group Description')

      visit path

      expect(page).not_to have_css('.group-home-desc h1')
    end

    it 'permits `rel` attribute on links' do
      group.update_attribute(:description, 'https://google.com/')

      visit path

      expect(page).to have_css('.group-home-desc a[rel]')
    end
  end

  describe 'group page with nested groups', js: true do
    let!(:group) { create(:group) }
    let!(:nested_group) { create(:group, parent: group) }
    let!(:path)  { group_path(group) }

    it 'has nested groups tab with nested groups inside' do
      visit path
      click_link 'Subgroups'

      expect(page).to have_content(nested_group.name)
    end
  end
end
