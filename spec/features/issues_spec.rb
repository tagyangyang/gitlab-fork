require 'spec_helper'

describe 'Issues', feature: true do
  include DropzoneHelper
  include IssueHelpers
  include SortingHelper
  include WaitForAjax

  let(:project) { create(:project, :public) }

  before do
    login_as :user
    user2 = create(:user)

    project.team << [[@user, user2], :developer]

    project.repository.create_file(
      @user,
      '.gitlab/issue_templates/bug.md',
      'this is a test "bug" template',
      message: 'added issue template',
      branch_name: 'master')
  end

  describe 'Edit issue' do
    let!(:issue) do
      create(:issue,
             author: @user,
             assignee: @user,
             project: project)
    end

    before do
      visit edit_namespace_project_issue_path(project.namespace, project, issue)
      find('.js-zen-enter').click
    end

    it 'opens new issue popup' do
      expect(page).to have_content("Issue ##{issue.iid}")
    end

    describe 'fill in' do
      before do
        fill_in 'issue_title', with: 'bug 345'
        fill_in 'issue_description', with: 'bug description'
      end
    end
  end

  describe 'Editing issue assignee' do
    let!(:issue) do
      create(:issue,
             author: @user,
             assignee: @user,
             project: project)
    end

    it 'allows user to select unassigned', js: true do
      visit edit_namespace_project_issue_path(project.namespace, project, issue)

      expect(page).to have_content "Assignee #{@user.name}"

      first('.js-user-search').click
      click_link 'Unassigned'

      click_button 'Save changes'

      page.within('.assignee') do
        expect(page).to have_content 'No assignee - assign yourself'
      end

      expect(issue.reload.assignee).to be_nil
    end
  end

  describe 'due date', js: true do
    context 'on new form' do
      before do
        visit new_namespace_project_issue_path(project.namespace, project)
      end

      it 'saves with due date' do
        date = Date.today.at_beginning_of_month

        fill_in 'issue_title', with: 'bug 345'
        fill_in 'issue_description', with: 'bug description'
        find('#issuable-due-date').click

        page.within '.pika-single' do
          click_button date.day
        end

        expect(find('#issuable-due-date').value).to eq date.to_s

        click_button 'Submit issue'

        page.within '.issuable-sidebar' do
          expect(page).to have_content date.to_s(:medium)
        end
      end
    end

    context 'on edit form' do
      let(:issue) { create(:issue, author: @user, project: project, due_date: Date.today.at_beginning_of_month.to_s) }

      before do
        visit edit_namespace_project_issue_path(project.namespace, project, issue)
      end

      it 'saves with due date' do
        date = Date.today.at_beginning_of_month

        expect(find('#issuable-due-date').value).to eq date.to_s

        date = date.tomorrow

        fill_in 'issue_title', with: 'bug 345'
        fill_in 'issue_description', with: 'bug description'
        find('#issuable-due-date').click

        page.within '.pika-single' do
          click_button date.day
        end

        expect(find('#issuable-due-date').value).to eq date.to_s

        click_button 'Save changes'

        page.within '.issuable-sidebar' do
          expect(page).to have_content date.to_s(:medium)
        end
      end

      it 'warns about version conflict' do
        issue.update(title: "New title")

        fill_in 'issue_title', with: 'bug 345'
        fill_in 'issue_description', with: 'bug description'

        click_button 'Save changes'

        expect(page).to have_content 'Someone edited the issue the same time you did'
      end
    end
  end

  describe 'Issue info' do
    it 'excludes award_emoji from comment count' do
      issue = create(:issue, author: @user, assignee: @user, project: project, title: 'foobar')
      create(:award_emoji, awardable: issue)

      visit namespace_project_issues_path(project.namespace, project, assignee_id: @user.id)

      expect(page).to have_content 'foobar'
      expect(page.all('.no-comments').first.text).to eq "0"
    end
  end

  describe 'Filter issue' do
    before do
      %w(foobar barbaz gitlab).each do |title|
        create(:issue,
               author: @user,
               assignee: @user,
               project: project,
               title: title)
      end

      @issue = Issue.find_by(title: 'foobar')
      @issue.milestone = create(:milestone, project: project)
      @issue.assignee = nil
      @issue.save
    end

    let(:issue) { @issue }

    it 'allows filtering by issues with no specified assignee' do
      visit namespace_project_issues_path(project.namespace, project, assignee_id: IssuableFinder::NONE)

      expect(page).to have_content 'foobar'
      expect(page).not_to have_content 'barbaz'
      expect(page).not_to have_content 'gitlab'
    end

    it 'allows filtering by a specified assignee' do
      visit namespace_project_issues_path(project.namespace, project, assignee_id: @user.id)

      expect(page).not_to have_content 'foobar'
      expect(page).to have_content 'barbaz'
      expect(page).to have_content 'gitlab'
    end
  end

  describe 'filter issue' do
    titles = %w[foo bar baz]
    titles.each_with_index do |title, index|
      let!(title.to_sym) do
        create(:issue, title: title,
                       project: project,
                       created_at: Time.now - (index * 60))
      end
    end
    let(:newer_due_milestone) { create(:milestone, due_date: '2013-12-11') }
    let(:later_due_milestone) { create(:milestone, due_date: '2013-12-12') }

    it 'sorts by newest' do
      visit namespace_project_issues_path(project.namespace, project, sort: sort_value_recently_created)

      expect(first_issue).to include('foo')
      expect(last_issue).to include('baz')
    end

    it 'sorts by oldest' do
      visit namespace_project_issues_path(project.namespace, project, sort: sort_value_oldest_created)

      expect(first_issue).to include('baz')
      expect(last_issue).to include('foo')
    end

    it 'sorts by most recently updated' do
      baz.updated_at = Time.now + 100
      baz.save
      visit namespace_project_issues_path(project.namespace, project, sort: sort_value_recently_updated)

      expect(first_issue).to include('baz')
    end

    it 'sorts by least recently updated' do
      baz.updated_at = Time.now - 100
      baz.save
      visit namespace_project_issues_path(project.namespace, project, sort: sort_value_oldest_updated)

      expect(first_issue).to include('baz')
    end

    describe 'sorting by due date' do
      before do
        foo.update(due_date: 1.day.from_now)
        bar.update(due_date: 6.days.from_now)
      end

      it 'sorts by recently due date' do
        visit namespace_project_issues_path(project.namespace, project, sort: sort_value_due_date_soon)

        expect(first_issue).to include('foo')
      end

      it 'sorts by least recently due date' do
        visit namespace_project_issues_path(project.namespace, project, sort: sort_value_due_date_later)

        expect(first_issue).to include('bar')
      end

      it 'sorts by least recently due date by excluding nil due dates' do
        bar.update(due_date: nil)

        visit namespace_project_issues_path(project.namespace, project, sort: sort_value_due_date_later)

        expect(first_issue).to include('foo')
      end

      context 'with a filter on labels' do
        let(:label) { create(:label, project: project) }
        before { create(:label_link, label: label, target: foo) }

        it 'sorts by least recently due date by excluding nil due dates' do
          bar.update(due_date: nil)

          visit namespace_project_issues_path(project.namespace, project, label_names: [label.name], sort: sort_value_due_date_later)

          expect(first_issue).to include('foo')
        end
      end
    end

    describe 'filtering by due date' do
      before do
        foo.update(due_date: 1.day.from_now)
        bar.update(due_date: 6.days.from_now)
      end

      it 'filters by none' do
        visit namespace_project_issues_path(project.namespace, project, due_date: Issue::NoDueDate.name)

        expect(page).not_to have_content('foo')
        expect(page).not_to have_content('bar')
        expect(page).to have_content('baz')
      end

      it 'filters by any' do
        visit namespace_project_issues_path(project.namespace, project, due_date: Issue::AnyDueDate.name)

        expect(page).to have_content('foo')
        expect(page).to have_content('bar')
        expect(page).to have_content('baz')
      end

      it 'filters by due this week' do
        foo.update(due_date: Date.today.beginning_of_week + 2.days)
        bar.update(due_date: Date.today.end_of_week)
        baz.update(due_date: Date.today - 8.days)

        visit namespace_project_issues_path(project.namespace, project, due_date: Issue::DueThisWeek.name)

        expect(page).to have_content('foo')
        expect(page).to have_content('bar')
        expect(page).not_to have_content('baz')
      end

      it 'filters by due this month' do
        foo.update(due_date: Date.today.beginning_of_month + 2.days)
        bar.update(due_date: Date.today.end_of_month)
        baz.update(due_date: Date.today - 50.days)

        visit namespace_project_issues_path(project.namespace, project, due_date: Issue::DueThisMonth.name)

        expect(page).to have_content('foo')
        expect(page).to have_content('bar')
        expect(page).not_to have_content('baz')
      end

      it 'filters by overdue' do
        foo.update(due_date: Date.today + 2.days)
        bar.update(due_date: Date.today + 20.days)
        baz.update(due_date: Date.yesterday)

        visit namespace_project_issues_path(project.namespace, project, due_date: Issue::Overdue.name)

        expect(page).not_to have_content('foo')
        expect(page).not_to have_content('bar')
        expect(page).to have_content('baz')
      end
    end

    describe 'sorting by milestone' do
      before do
        foo.milestone = newer_due_milestone
        foo.save
        bar.milestone = later_due_milestone
        bar.save
      end

      it 'sorts by recently due milestone' do
        visit namespace_project_issues_path(project.namespace, project, sort: sort_value_milestone_soon)

        expect(first_issue).to include('foo')
        expect(last_issue).to include('baz')
      end

      it 'sorts by least recently due milestone' do
        visit namespace_project_issues_path(project.namespace, project, sort: sort_value_milestone_later)

        expect(first_issue).to include('bar')
        expect(last_issue).to include('baz')
      end
    end

    describe 'combine filter and sort' do
      let(:user2) { create(:user) }

      before do
        foo.assignee = user2
        foo.save
        bar.assignee = user2
        bar.save
      end

      it 'sorts with a filter applied' do
        visit namespace_project_issues_path(project.namespace, project,
                                            sort: sort_value_oldest_created,
                                            assignee_id: user2.id)

        expect(first_issue).to include('bar')
        expect(last_issue).to include('foo')
        expect(page).not_to have_content 'baz'
      end
    end
  end

  describe 'when I want to reset my incoming email token' do
    let(:project1) { create(:project, namespace: @user.namespace) }
    let!(:issue) { create(:issue, project: project1) }

    before do
      stub_incoming_email_setting(enabled: true, address: "p+%{key}@gl.ab")
      project1.team << [@user, :master]
      visit namespace_project_issues_path(@user.namespace, project1)
    end

    it 'changes incoming email address token', js: true do
      find('.issue-email-modal-btn').click
      previous_token = find('input#issue_email').value
      find('.incoming-email-token-reset').trigger('click')

      wait_for_ajax

      expect(page).to have_no_field('issue_email', with: previous_token)
      new_token = project1.new_issue_address(@user.reload)
      expect(page).to have_field(
        'issue_email',
        with: new_token
      )
    end
  end

  describe 'update labels from issue#show', js: true do
    let(:issue) { create(:issue, project: project, author: @user, assignee: @user) }
    let!(:label) { create(:label, project: project) }

    before do
      visit namespace_project_issue_path(project.namespace, project, issue)
    end

    it 'will not send ajax request when no data is changed' do
      page.within '.labels' do
        click_link 'Edit'
        first('.dropdown-menu-close').click

        expect(page).not_to have_selector('.block-loading')
      end
    end
  end

  describe 'update assignee from issue#show' do
    let(:issue) { create(:issue, project: project, author: @user, assignee: @user) }

    context 'by authorized user' do
      it 'allows user to select unassigned', js: true do
        visit namespace_project_issue_path(project.namespace, project, issue)

        page.within('.assignee') do
          expect(page).to have_content "#{@user.name}"

          click_link 'Edit'
          click_link 'Unassigned'
          expect(page).to have_content 'No assignee'
        end

        expect(issue.reload.assignee).to be_nil
      end

      it 'allows user to select an assignee', js: true do
        issue2 = create(:issue, project: project, author: @user)
        visit namespace_project_issue_path(project.namespace, project, issue2)

        page.within('.assignee') do
          expect(page).to have_content "No assignee"
        end

        page.within '.assignee' do
          click_link 'Edit'
        end

        page.within '.dropdown-menu-user' do
          click_link @user.name
        end

        page.within('.assignee') do
          expect(page).to have_content @user.name
        end
      end

      it 'allows user to unselect themselves', js: true do
        issue2 = create(:issue, project: project, author: @user)
        visit namespace_project_issue_path(project.namespace, project, issue2)

        page.within '.assignee' do
          click_link 'Edit'
          click_link @user.name

          page.within '.value' do
            expect(page).to have_content @user.name
          end

          click_link 'Edit'
          click_link @user.name

          page.within '.value' do
            expect(page).to have_content "No assignee"
          end
        end
      end
    end

    context 'by unauthorized user' do
      let(:guest) { create(:user) }

      before do
        project.team << [[guest], :guest]
      end

      it 'shows assignee text', js: true do
        logout
        login_with guest

        visit namespace_project_issue_path(project.namespace, project, issue)
        expect(page).to have_content issue.assignee.name
      end
    end
  end

  describe 'update milestone from issue#show' do
    let!(:issue) { create(:issue, project: project, author: @user) }
    let!(:milestone) { create(:milestone, project: project) }

    context 'by authorized user' do
      it 'allows user to select unassigned', js: true do
        visit namespace_project_issue_path(project.namespace, project, issue)

        page.within('.milestone') do
          expect(page).to have_content "None"
        end

        find('.block.milestone .edit-link').click
        sleep 2 # wait for ajax stuff to complete
        first('.dropdown-content li').click
        sleep 2
        page.within('.milestone') do
          expect(page).to have_content 'None'
        end

        expect(issue.reload.milestone).to be_nil
      end

      it 'allows user to de-select milestone', js: true do
        visit namespace_project_issue_path(project.namespace, project, issue)

        page.within('.milestone') do
          click_link 'Edit'
          click_link milestone.title

          page.within '.value' do
            expect(page).to have_content milestone.title
          end

          click_link 'Edit'
          click_link milestone.title

          page.within '.value' do
            expect(page).to have_content 'None'
          end
        end
      end
    end

    context 'by unauthorized user' do
      let(:guest) { create(:user) }

      before do
        project.team << [guest, :guest]
        issue.milestone = milestone
        issue.save
      end

      it 'shows milestone text', js: true do
        logout
        login_with guest

        visit namespace_project_issue_path(project.namespace, project, issue)
        expect(page).to have_content milestone.title
      end
    end

    describe 'removing assignee' do
      let(:user2) { create(:user) }

      before do
        issue.assignee = user2
        issue.save
      end
    end
  end

  describe 'new issue' do
    context 'by unauthenticated user' do
      before do
        logout
      end

      it 'redirects to signin then back to new issue after signin' do
        visit namespace_project_issues_path(project.namespace, project)

        click_link 'New issue'

        expect(current_path).to eq new_user_session_path

        login_as :user

        expect(current_path).to eq new_namespace_project_issue_path(project.namespace, project)
      end
    end

    context 'dropzone upload file', js: true do
      before do
        visit new_namespace_project_issue_path(project.namespace, project)
      end

      it 'uploads file when dragging into textarea' do
        dropzone_file Rails.root.join('spec', 'fixtures', 'banana_sample.gif')

        expect(page.find_field("issue_description").value).to have_content 'banana_sample'
      end

      it 'adds double newline to end of attachment markdown' do
        dropzone_file Rails.root.join('spec', 'fixtures', 'banana_sample.gif')

        expect(page.find_field("issue_description").value).to match /\n\n$/
      end
    end

    context 'form filled by URL parameters' do
      before do
        visit new_namespace_project_issue_path(project.namespace, project, issuable_template: 'bug')
      end

      it 'fills in template' do
        expect(find('.js-issuable-selector .dropdown-toggle-text')).to have_content('bug')
      end
    end
  end

  describe 'new issue by email' do
    shared_examples 'show the email in the modal' do
      let(:issue) { create(:issue, project: project) }

      before do
        project.issues << issue
        stub_incoming_email_setting(enabled: true, address: "p+%{key}@gl.ab")

        visit namespace_project_issues_path(project.namespace, project)
        click_button('Email a new issue')
      end

      it 'click the button to show modal for the new email' do
        page.within '#issue-email-modal' do
          email = project.new_issue_address(@user)

          expect(page).to have_selector("input[value='#{email}']")
        end
      end
    end

    context 'with existing issues' do
      let!(:issue) { create(:issue, project: project, author: @user) }

      it_behaves_like 'show the email in the modal'
    end

    context 'without existing issues' do
      it_behaves_like 'show the email in the modal'
    end
  end

  describe 'due date' do
    context 'update due on issue#show', js: true do
      let(:issue) { create(:issue, project: project, author: @user, assignee: @user) }

      before do
        visit namespace_project_issue_path(project.namespace, project, issue)
      end

      it 'adds due date to issue' do
        date = Date.today.at_beginning_of_month + 2.days

        page.within '.due_date' do
          click_link 'Edit'

          page.within '.pika-single' do
            click_button date.day
          end

          wait_for_ajax

          expect(find('.value').text).to have_content date.strftime('%b %-d, %Y')
        end
      end

      it 'removes due date from issue' do
        date = Date.today.at_beginning_of_month + 2.days

        page.within '.due_date' do
          click_link 'Edit'

          page.within '.pika-single' do
            click_button date.day
          end

          wait_for_ajax

          expect(page).to have_no_content 'No due date'

          click_link 'remove due date'
          expect(page).to have_content 'No due date'
        end
      end
    end
  end

  describe 'title issue#show', js: true do
    include WaitForVueResource

    it 'updates the title', js: true do
      issue = create(:issue, author: @user, assignee: @user, project: project, title: 'new title')

      visit namespace_project_issue_path(project.namespace, project, issue)

      expect(page).to have_text("new title")

      issue.update(title: "updated title")

      wait_for_vue_resource
      expect(page).to have_text("updated title")
    end
  end
end
