require 'spec_helper'

describe 'Dashboard Groups page', js: true, feature: true do
  include WaitForAjax

  let!(:user) { create :user }
  let!(:group) { create(:group) }
  let!(:nested_group) { create(:group, :nested) }
  let!(:another_group) { create(:group) }

  before do
    group.add_owner(user)
    nested_group.add_owner(user)

    login_as(user)

    page.visit dashboard_groups_path
  end

  it 'shows groups user is member of' do
    expect(page).to have_content(group.full_name)
    expect(page).to have_content(nested_group.full_name)
    expect(page).not_to have_content(another_group.full_name)
  end

  it 'filters groups' do
    fill_in 'filter_groups', with: group.name
    wait_for_ajax

    expect(page).to have_content(group.full_name)
    expect(page).not_to have_content(nested_group.full_name)
    expect(page).not_to have_content(another_group.full_name)
  end

  it 'resets search when user cleans the input' do
    fill_in 'filter_groups', with: group.name
    wait_for_ajax

    fill_in 'filter_groups', with: ""
    wait_for_ajax

    expect(page).to have_content(group.full_name)
    expect(page).to have_content(nested_group.full_name)
    expect(page).not_to have_content(another_group.full_name)
    expect(page.all('.js-groups-list-holder .content-list li').length).to eq 2
  end

  it 'sorts groups' do
    click_button 'Last created'
    click_link 'Oldest updated'

    expect(page).to have_current_path('/dashboard/groups?sort=updated_asc')
    expect(page).to have_content(group.full_name)
    expect(page).to have_content(nested_group.full_name)
  end
end
