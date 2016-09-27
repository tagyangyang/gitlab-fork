require 'spec_helper'

feature 'Explore Projects Tab', feature: true, js: true do
  include WaitForAjax

  before do
    create(:group, name: 'TestGroup', visibility_level: Gitlab::VisibilityLevel::PRIVATE)

    login_as user
    visit explore_groups_path
    wait_for_ajax
  end

  context 'as an auditor' do
    let(:user) { create(:auditor) }

    it 'shows private groups' do
      expect(page).to have_content "TestGroup"
    end
  end

  context 'as a regular user' do
    let(:user) { create(:user) }

    it 'does not show private groups' do
      expect(page).not_to have_content "TestGroup"
    end
  end
end
