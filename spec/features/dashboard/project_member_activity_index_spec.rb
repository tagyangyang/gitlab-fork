require 'spec_helper'

feature 'Project member activity', feature: true, js: true do
  include WaitForAjax

  let(:user)            { create(:user) }
  let(:project)         { create(:empty_project, :public, name: 'x', namespace: user.namespace) }

  before do
    project.team << [user, :master]
  end

  def visit_activities_and_wait_with_event(event_type)
    Event.create(project: project, author_id: user.id, action: event_type)
    visit activity_namespace_project_path(project.namespace, project)
    wait_for_ajax
  end

  subject { page.find(".event-title").text }

  context 'when a user joins the project' do
    before { visit_activities_and_wait_with_event(Event::JOINED) }

    it { is_expected.to eq("joined project") }
  end

  context 'when a user leaves the project' do
    before { visit_activities_and_wait_with_event(Event::LEFT) }

    it { is_expected.to eq("left project") }
  end

  context 'when a users membership expires for the project' do
    before { visit_activities_and_wait_with_event(Event::EXPIRED) }

    it "presents the correct message" do
      message = "removed due to membership expiration from project"
      is_expected.to eq(message)
    end
  end
end
