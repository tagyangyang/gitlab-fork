require 'spec_helper'

feature 'RavenJS', :feature, :js do
  let(:raven_path) { '/raven.bundle.js' }

  it 'should not load raven if sentry is disabled' do
    visit new_user_session_path

    expect(has_requested_raven).to eq(false)
  end

  it 'should load raven if sentry is enabled' do
    allow_any_instance_of(SentryHelper).to receive_messages(sentry_dsn_public: 'https://key@domain.com/id',
                                                            sentry_enabled?: true)

    visit new_user_session_path

    expect(has_requested_raven).to eq(true)
  end

  def has_requested_raven
    page.driver.network_traffic.one? {|request| request.url.end_with?(raven_path)}
  end
end
