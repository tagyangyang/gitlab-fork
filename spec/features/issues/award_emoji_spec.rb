require 'rails_helper'

describe 'Awards Emoji', feature: true do
  include WaitForAjax
  include WaitForVueResource

  let!(:project)   { create(:project, :public) }
  let!(:user)      { create(:user) }
  let(:issue) do
    create(:issue,
           assignee: @user,
           project: project)
  end

  context 'authorized user' do
    before do
      project.team << [user, :master]
      login_as(user)
    end

    describe 'visiting an issue with a legacy award emoji that is not valid anymore' do
      before do
        # The `heart_tip` emoji is not valid anymore so we need to skip validation
        issue.award_emoji.build(user: user, name: 'heart_tip').save!(validate: false)
        visit namespace_project_issue_path(project.namespace, project, issue)
        wait_for_vue_resource
      end

      # Regression test: https://gitlab.com/gitlab-org/gitlab-ce/issues/29529
      it 'does not shows a 500 page', js: true do
        expect(page).to have_text(issue.title)
      end
    end

    describe 'Click award emoji from issue#show' do
      let!(:note) { create(:note_on_issue, noteable: issue, project: issue.project, note: "Hello world") }

      before do
        visit namespace_project_issue_path(project.namespace, project, issue)
        wait_for_vue_resource
      end

      it 'increments the thumbsdown emoji', js: true do
        find('[data-name="thumbsdown"]').click
        wait_for_ajax
        expect(thumbsdown_emoji).to have_text("1")
      end

      context 'click the thumbsup emoji' do
        it 'increments the thumbsup emoji', js: true do
          find('[data-name="thumbsup"]').click
          wait_for_ajax
          expect(thumbsup_emoji).to have_text("1")
        end

        it 'decrements the thumbsdown emoji', js: true do
          expect(thumbsdown_emoji).to have_text("0")
        end
      end

      context 'click the thumbsdown emoji' do
        it 'increments the thumbsdown emoji', js: true do
          find('[data-name="thumbsdown"]').click
          wait_for_ajax
          expect(thumbsdown_emoji).to have_text("1")
        end

        it 'decrements the thumbsup emoji', js: true do
          expect(thumbsup_emoji).to have_text("0")
        end
      end

      it 'toggles the smiley emoji on a note', js: true do
        toggle_smiley_emoji(true)

        within('.note-awards') do
          expect(find(emoji_counter)).to have_text("1")
        end

        toggle_smiley_emoji(false)

        within('.note-awards') do
          expect(page).not_to have_selector(emoji_counter)
        end
      end

      context 'execute /award slash command' do
        it 'toggles the emoji award on noteable', js: true do
          execute_slash_command('/award :100:')

          expect(find(noteable_award_counter)).to have_text("1")

          execute_slash_command('/award :100:')

          expect(page).not_to have_selector(noteable_award_counter)
        end
      end
    end
  end

  context 'unauthorized user', js: true do
    before do
      visit namespace_project_issue_path(project.namespace, project, issue)
    end

    it 'has disabled emoji button' do
      expect(first('.award-control')[:class]).to have_text('disabled')
    end
  end

  def execute_slash_command(cmd)
    within('.js-main-target-form') do
      fill_in 'note[note]', with: cmd
      click_button 'Comment'
    end

    wait_for_ajax
  end

  def thumbsup_emoji
    page.all(emoji_counter).first
  end

  def thumbsdown_emoji
    page.all(emoji_counter).last
  end

  def emoji_counter
    'span.js-counter'
  end

  def noteable_award_counter
    ".awards .active"
  end

  def toggle_smiley_emoji(status)
    within('.note') do
      find('.note-emoji-button').click
    end

    unless status
      first('[data-name="smiley"]').click
    else
      find('[data-name="smiley"]').click
    end

    wait_for_ajax
  end
end
