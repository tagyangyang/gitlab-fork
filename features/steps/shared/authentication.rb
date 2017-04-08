require Rails.root.join('features', 'support', 'login_helpers')

module SharedAuthentication
  include Spinach::DSL
  include LoginHelpers

  step 'I sign in as a user' do
    @user = create(:user)

    sign_in(@user)
  end

  step 'I sign in via the UI' do
    @user = create(:user)

    gitlab_sign_in(@user)
  end

  step 'I sign in as an admin' do
    @user = create(:admin)
    sign_in(@user)
  end

  step 'I sign in as "John Doe"' do
    gitlab_sign_in(user_exists("John Doe"))
  end

  step 'I sign in as "Mary Jane"' do
    gitlab_sign_in(user_exists("Mary Jane"))
  end

  step 'I should be redirected to sign in page' do
    expect(current_path).to eq new_user_session_path
  end

  step "I logout" do
    gitlab_sign_out
  end

  step "I logout directly" do
    gitlab_sign_out
  end

  def current_user
    @user || User.reorder(nil).first
  end

  private

  def gitlab_sign_in(user)
    visit new_user_session_path

    fill_in "user_login", with: user.email
    fill_in "user_password", with: "12345678"
    check 'user_remember_me'
    click_button "Sign in"

    @user = user
  end

  def gitlab_sign_out
    return unless @user

    if Capybara.current_driver == Capybara.javascript_driver
      find('.header-user-dropdown-toggle').click
      click_link 'Sign out'
      expect(page).to have_button('Sign in')
    else
      sign_out(@user)
    end

    @user = nil
  end
end
