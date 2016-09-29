require 'spec_helper'

feature 'Explore Projects Tab', feature: true, js: true do
  include WaitForAjax

  before do
    create :project, :public, name: 'Community Project'
    create :project, :internal, name: 'Internal Project'
    create :project, name: 'Enterprise Project'
    create :project, :public, archived: true, name: 'Archived Project'

    login_as user
    visit explore_projects_path
    wait_for_ajax
  end

  context 'as an auditor' do
    let(:user) { create(:auditor) }

    it 'shows all projects' do
      expect(page).to have_content 'Enterprise Project'
      expect(page).to have_content 'Internal Project'
      expect(page).to have_content 'Community Project'
      expect(page).not_to have_content 'Archive Project'
    end
  end

  context 'as a regular user' do
    let(:user) { create(:user) }

    it 'shows public projects' do
      expect(page).to have_content 'Community Project'
      expect(page).to have_content 'Internal Project'
      expect(page).not_to have_content 'Enterprise Project'
      expect(page).not_to have_content 'Archive Project'
    end
  end
end
