require 'spec_helper'

feature 'Labels', feature: true do
  include WaitForAjax

  describe 'user toggle subscription' do
    before do
      user = create(:user)
      project = create(:project, namespace: user.namespace)
      create(:label, project: project, title: 'numbers')

      login_as user
      visit namespace_project_labels_path(project.namespace, project)
    end

    it 'button changes state', js: true do
      expect(page).to have_css('button.js-subscribe-button[data-status="unsubscribed"]')

      first('button.js-subscribe-button').click

      wait_for_ajax

      expect(page).to have_css('button.js-subscribe-button[data-status="subscribed"]')
    end
  end
end
