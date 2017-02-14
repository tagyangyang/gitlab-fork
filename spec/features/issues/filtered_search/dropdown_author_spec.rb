require 'spec_helper'

describe 'Dropdown author', js: true, feature: true do
  let(:project) { create(:empty_project) }
  let!(:user) { create(:user, name: 'administrator', username: 'root') }
  let!(:user_john) { create(:user, name: 'John', username: 'th0mas') }
  let!(:user_jacob) { create(:user, name: 'Jacob', username: 'otter32') }
  let(:filtered_search) { find('.filtered-search') }
  let(:js_dropdown_author) { '#js-dropdown-author' }
  let(:filter_dropdown) { find("#{js_dropdown_author} .filter-dropdown") }

  def init_author_search
    filtered_search.set('author:')
    # This ensures the dropdown is shown
    expect(find(js_dropdown_author)).not_to have_css('.filter-dropdown-loading')
  end

  def search_for_author(author)
    init_author_search
    filtered_search.send_keys(author)
  end

  def click_author(text)
    filter_dropdown.find('.filter-dropdown-item', text: text).click
  end

  def dropdown_author_size
    filter_dropdown.all('.filter-dropdown-item').size
  end

  def clear_search_field
    find('.filtered-search-input-container .clear-search').click
  end

  before do
    project.add_master(user)
    project.add_master(user_john)
    project.add_master(user_jacob)
    login_as(user)
    create(:issue, project: project)

    visit namespace_project_issues_path(project.namespace, project)
  end

  # describe 'behavior' do
  #   it 'opens when the search bar has author:' do
  #     filtered_search.set('author:')

  #     expect(page).to have_css(js_dropdown_author)
  #   end

  #   it 'closes when the search bar is unfocused' do
  #     find('body').click()

  #     expect(page).not_to have_css(js_dropdown_author)
  #   end

  #   it 'shows loading indicator when opened and hides it when loaded' do
  #     filtered_search.set('author:')

  #     expect(page).to have_css('#js-dropdown-author .filter-dropdown-loading', visible: true)

  #     expect(find(js_dropdown_author)).to have_css('.filter-dropdown-loading')
  #     expect(find(js_dropdown_author)).not_to have_css('.filter-dropdown-loading')
  #   end

  #   it 'should load all the authors when opened' do
  #     # send_keys_to_filtered_search('author:')
  #     filtered_search.set('author:')

  #     page.within '#js-dropdown-author .filter-dropdown' do
  #       expect(dropdown_author_size).to eq(3)
  #     end
  #   end

  #   it 'shows current user at top of dropdown' do
  #     filtered_search.set('author:')

  #     page.within '#js-dropdown-author .filter-dropdown' do
  #       expect(first('#js-dropdown-author li')).to have_content(user.name)
  #     end
  #   end
  # end

  describe 'filtering' do
    before do
      init_author_search
    end

    it 'filters by name' do
      search_for_author('ja')

      expect(filter_dropdown.find('.filter-dropdown-item', text: user_jacob.name)).to be_visible
      expect(dropdown_author_size).to eq(1)

      clear_search_field
      init_author_search

      search_for_author('@ja')

      expect(filter_dropdown.find('.filter-dropdown-item', text: user_jacob.name)).to be_visible
      expect(dropdown_author_size).to eq(1)
    end

    # it 'filters by case insensitive name' do
    #   send_keys_to_filtered_search('Ja')

    #   page.within '#js-dropdown-author .filter-dropdown' do
    #     expect(dropdown_author_size).to eq(1)
    #   end
    # end

    # it 'filters by username with symbol' do
    #   send_keys_to_filtered_search('@ot')

    #   page.within '#js-dropdown-author .filter-dropdown' do
    #     expect(dropdown_author_size).to eq(2)
    #   end
    # end

    # it 'filters by username without symbol' do
    #   send_keys_to_filtered_search('ot')

    #   page.within '#js-dropdown-author .filter-dropdown' do
    #     expect(dropdown_author_size).to eq(2)
    #   end
    # end

    # it 'filters by case insensitive username without symbol' do
    #   send_keys_to_filtered_search('OT')

    #   page.within '#js-dropdown-author .filter-dropdown' do
    #     expect(dropdown_author_size).to eq(2)
    #   end
    # end
  end

  # describe 'selecting from dropdown' do
  #   before do
  #     filtered_search.set('author')
  #     send_keys_to_filtered_search(':')
  #   end

  #   it 'fills in the author username when the author has not been filtered' do
  #     click_author(user_jacob.name)

  #     expect(page).to have_css(js_dropdown_author, visible: false)
  #     expect(filtered_search.value).to eq("author:@#{user_jacob.username} ")
  #   end

  #   it 'fills in the author username when the author has been filtered' do
  #     click_author(user.name)

  #     expect(page).to have_css(js_dropdown_author, visible: false)
  #     expect(filtered_search.value).to eq("author:@#{user.username} ")
  #   end
  # end

  # describe 'input has existing content' do
  #   it 'opens author dropdown with existing search term' do
  #     filtered_search.set('searchTerm author:')

  #     expect(page).to have_css(js_dropdown_author, visible: true)
  #   end

  #   it 'opens author dropdown with existing assignee' do
  #     filtered_search.set('assignee:@user author:')

  #     expect(page).to have_css(js_dropdown_author, visible: true)
  #   end

  #   it 'opens author dropdown with existing label' do
  #     filtered_search.set('label:~bug author:')

  #     expect(page).to have_css(js_dropdown_author, visible: true)
  #   end

  #   it 'opens author dropdown with existing milestone' do
  #     filtered_search.set('milestone:%v1.0 author:')

  #     expect(page).to have_css(js_dropdown_author, visible: true)
  #   end
  # end

  # describe 'caching requests' do
  #   it 'caches requests after the first load' do
  #     filtered_search.set('author')
  #     send_keys_to_filtered_search(':')
  #     initial_size = dropdown_author_size

  #     expect(initial_size).to be > 0

  #     new_user = create(:user)
  #     project.team << [new_user, :master]
  #     find('.filtered-search-input-container .clear-search').click
  #     filtered_search.set('author')
  #     send_keys_to_filtered_search(':')

  #     expect(dropdown_author_size).to eq(initial_size)
  #   end
  # end
end
