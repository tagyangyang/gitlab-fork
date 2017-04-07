require 'rails_helper'

describe 'Dropdown assignee', :feature, :js do
  include FilteredSearchHelpers
  include WaitForAjax

  let!(:project) { create(:empty_project) }
  let!(:user) { create(:user, name: 'administrator', username: 'root') }
  let!(:user_john) { create(:user, name: 'John', username: 'th0mas') }
  let!(:user_jacob) { create(:user, name: 'Jacob', username: 'otter32') }
  let(:filtered_search) { find('.filtered-search') }
  let(:js_dropdown_assignee) { '#js-dropdown-assignee' }
  let(:filter_dropdown) { find("#{js_dropdown_assignee} .filter-dropdown") }

  def dropdown_assignee_size
    filter_dropdown.all('.filter-dropdown-item').size
  end

  def click_assignee(text)
    find('#js-dropdown-assignee .filter-dropdown .filter-dropdown-item', text: text).click
  end

  before do
    project.team << [user, :master]
    project.team << [user_john, :master]
    project.team << [user_jacob, :master]
    login_as(user)
    create(:issue, project: project)

    visit namespace_project_issues_path(project.namespace, project)
  end

  describe 'behavior' do
    it 'opens when the search bar has assignee:' do
      filtered_search.set('assignee:')

      expect(page).to have_css(js_dropdown_assignee, visible: true)
    end

    it 'closes when the search bar is unfocused' do
      find('body').click()

      expect(page).to have_css(js_dropdown_assignee, visible: false)
    end

    it 'should show loading indicator when opened' do
      filtered_search.set('assignee:')

      expect(page).to have_css('#js-dropdown-assignee .filter-dropdown-loading', visible: true)
    end

    it 'should hide loading indicator when loaded' do
      filtered_search.set('assignee:')

      expect(find(js_dropdown_assignee)).to have_css('.filter-dropdown-loading')
      expect(find(js_dropdown_assignee)).not_to have_css('.filter-dropdown-loading')
    end

    it 'should load all the assignees when opened' do
      filtered_search.set('assignee:')

      expect(dropdown_assignee_size).to eq(3)
    end

    it 'shows current user at top of dropdown' do
      filtered_search.set('assignee:')

      expect(filter_dropdown.first('.filter-dropdown-item')).to have_content(user.name)
    end
  end

  describe 'filtering' do
    before do
      filtered_search.set('assignee:')

      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_content(user_john.name)
      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_content(user_jacob.name)
      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_content(user.name)
    end

    it 'filters by name' do
      filtered_search.send_keys('j')

      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_content(user_john.name)
      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_content(user_jacob.name)
      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_no_content(user.name)
    end

    it 'filters by case insensitive name' do
      filtered_search.send_keys('J')

      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_content(user_john.name)
      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_content(user_jacob.name)
      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_no_content(user.name)
    end

    it 'filters by username with symbol' do
      filtered_search.send_keys('@ot')

      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_content(user_jacob.name)
      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_content(user.name)
      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_no_content(user_john.name)
    end

    it 'filters by case insensitive username with symbol' do
      filtered_search.send_keys('@OT')

      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_content(user_jacob.name)
      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_content(user.name)
      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_no_content(user_john.name)
    end

    it 'filters by username without symbol' do
      filtered_search.send_keys('ot')

      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_content(user_jacob.name)
      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_content(user.name)
      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_no_content(user_john.name)
    end

    it 'filters by case insensitive username without symbol' do
      filtered_search.send_keys('OT')

      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_content(user_jacob.name)
      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_content(user.name)
      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_no_content(user_john.name)
    end
  end

  describe 'selecting from dropdown' do
    before do
      filtered_search.set('assignee:')
    end

    it 'fills in the assignee username when the assignee has not been filtered' do
      click_assignee(user_jacob.name)

      expect(page).to have_css(js_dropdown_assignee, visible: false)
      expect_tokens([{ name: 'assignee', value: "@#{user_jacob.username}" }])
      expect_filtered_search_input_empty
    end

    it 'fills in the assignee username when the assignee has been filtered' do
      filtered_search.send_keys('roo')
      click_assignee(user.name)

      expect(page).to have_css(js_dropdown_assignee, visible: false)
      expect_tokens([{ name: 'assignee', value: "@#{user.username}" }])
      expect_filtered_search_input_empty
    end

    it 'selects `no assignee`' do
      find('#js-dropdown-assignee .filter-dropdown-item', text: 'No Assignee').click

      expect(page).to have_css(js_dropdown_assignee, visible: false)
      expect_tokens([{ name: 'assignee', value: 'none' }])
      expect_filtered_search_input_empty
    end
  end

  describe 'input has existing content' do
    it 'opens assignee dropdown with existing search term' do
      filtered_search.set('searchTerm assignee:')

      expect(page).to have_css(js_dropdown_assignee, visible: true)
    end

    it 'opens assignee dropdown with existing author' do
      filtered_search.set('author:@user assignee:')

      expect(page).to have_css(js_dropdown_assignee, visible: true)
    end

    it 'opens assignee dropdown with existing label' do
      filtered_search.set('label:~bug assignee:')

      expect(page).to have_css(js_dropdown_assignee, visible: true)
    end

    it 'opens assignee dropdown with existing milestone' do
      filtered_search.set('milestone:%v1.0 assignee:')

      expect(page).to have_css(js_dropdown_assignee, visible: true)
    end
  end

  describe 'caching requests' do
    it 'caches requests after the first load' do
      filtered_search.set('assignee')
      filtered_search.send_keys(':')
      initial_size = dropdown_assignee_size

      expect(initial_size).to be > 0

      new_user = create(:user)
      project.team << [new_user, :master]
      find('.filtered-search-box .clear-search').click
      filtered_search.set('assignee')
      filtered_search.send_keys(':')

      expect(dropdown_assignee_size).to eq(initial_size)
    end
  end
end
