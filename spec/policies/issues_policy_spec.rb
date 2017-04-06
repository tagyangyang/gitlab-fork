require 'spec_helper'

describe IssuePolicy, models: true do
  let(:guest) { create(:user) }
  let(:author) { create(:user) }
  let(:assignee) { create(:user) }
  let(:reporter) { create(:user) }
  let(:group) { create(:group, :public) }
  let(:reporter_from_group_link) { create(:user) }

  def permissions(user, issue)
    Ability.policy_for(user, issue)
  end

  def expect_allowed(user, issue, *perms)
    perms.each do |p|
      expect(permissions(user, issue)).to be_allowed(p)
    end
  end

  def expect_disallowed(user, issue, *perms)
    perms.each do |p|
      expect(permissions(user, issue)).not_to be_allowed(p)
    end
  end

  context 'a private project' do
    let(:non_member) { create(:user) }
    let(:project) { create(:empty_project, :private) }
    let(:issue) { create(:issue, project: project, assignee: assignee, author: author) }
    let(:issue_no_assignee) { create(:issue, project: project) }

    before do
      project.team << [guest, :guest]
      project.team << [author, :guest]
      project.team << [assignee, :guest]
      project.team << [reporter, :reporter]

      group.add_reporter(reporter_from_group_link)

      create(:project_group_link, group: group, project: project)
    end

    it 'does not allow non-members to read issues' do
      expect_disallowed(non_member, issue, :read_issue, :update_issue, :admin_issue)
      expect_disallowed(non_member, issue_no_assignee, :read_issue, :update_issue, :admin_issue)
    end

    it 'allows guests to read issues' do
      binding.pry
      expect_allowed(guest, issue, :read_issue)
      expect_disallowed(guest, issue, :update_issue, :admin_issue)

      expect_allowed(guest, issue_no_assignee, :read_issue)
      expect_disallowed(guest, issue_no_assignee, :update_issue, :admin_issue)
    end

    it 'allows reporters to read, update, and admin issues' do
      expect_allowed(reporter, issue, :read_issue, :update_issue, :admin_issue)
      expect_allowed(reporter, issue_no_assignee, :read_issue, :update_issue, :admin_issue)
    end

    it 'allows reporters from group links to read, update, and admin issues' do
      expect_allowed(reporter_from_group_link, issue, :read_issue, :update_issue, :admin_issue)
      expect_allowed(reporter_from_group_link, issue_no_assignee, :read_issue, :update_issue, :admin_issue)
    end

    it 'allows issue authors to read and update their issues' do
      expect_allowed(author, issue, :read_issue, :update_issue)
      expect_disallowed(author, issue, :admin_issue)

      expect_allowed(author, issue_no_assignee, :read_issue)
      expect_disallowed(author, issue_no_assignee, :update_issue, :admin_issue)
    end

    it 'allows issue assignees to read and update their issues' do
      expect_allowed(assignee, issue, :read_issue, :update_issue)
      expect_disallowed(assignee, issue, :admin_issue)

      expect_allowed(assignee, issue_no_assignee, :read_issue)
      expect_disallowed(assignee, issue_no_assignee, :update_issue, :admin_issue)
    end

    context 'with confidential issues' do
      let(:confidential_issue) { create(:issue, :confidential, project: project, assignee: assignee, author: author) }
      let(:confidential_issue_no_assignee) { create(:issue, :confidential, project: project) }

      it 'does not allow non-members to read confidential issues' do
        expect_disallowed(non_member, confidential_issue, :read_issue, :update_issue, :admin_issue)
        expect_disallowed(non_member, confidential_issue_no_assignee, :read_issue, :update_issue, :admin_issue)
      end

      it 'does not allow guests to read confidential issues' do
        expect_disallowed(guest, confidential_issue, :read_issue, :update_issue, :admin_issue)
        expect_disallowed(guest, confidential_issue_no_assignee, :read_issue, :update_issue, :admin_issue)
      end

      it 'allows reporters to read, update, and admin confidential issues' do
        expect_allowed(reporter, confidential_issue, :read_issue, :update_issue, :admin_issue)
        expect_allowed(reporter, confidential_issue_no_assignee, :read_issue, :update_issue, :admin_issue)
      end

      it 'allows reporters from group links to read, update, and admin confidential issues' do
        expect_allowed(reporter_from_group_link, confidential_issue, :read_issue, :update_issue, :admin_issue)
        expect_allowed(reporter_from_group_link, confidential_issue_no_assignee, :read_issue, :update_issue, :admin_issue)
      end

      it 'allows issue authors to read and update their confidential issues' do
        expect_allowed(author, confidential_issue, :read_issue, :update_issue)
        expect_disallowed(author, confidential_issue, :admin_issue)

        expect_disallowed(author, confidential_issue_no_assignee, :read_issue, :update_issue, :admin_issue)
      end

      it 'allows issue assignees to read and update their confidential issues' do
        expect_allowed(assignee, confidential_issue, :read_issue, :update_issue)
        expect_disallowed(assignee, confidential_issue, :admin_issue)

        expect_disallowed(assignee, confidential_issue_no_assignee, :read_issue, :update_issue, :admin_issue)
      end
    end
  end

  context 'a public project' do
    let(:project) { create(:empty_project, :public) }
    let(:issue) { create(:issue, project: project, assignee: assignee, author: author) }
    let(:issue_no_assignee) { create(:issue, project: project) }

    before do
      project.team << [guest, :guest]
      project.team << [reporter, :reporter]

      group.add_reporter(reporter_from_group_link)

      create(:project_group_link, group: group, project: project)
    end

    it 'allows guests to read issues' do
      expect_allowed(guest, issue, :read_issue)
      expect_disallowed(guest, issue, :update_issue, :admin_issue)

      expect_allowed(guest, issue_no_assignee, :read_issue)
      expect_disallowed(guest, issue_no_assignee, :update_issue, :admin_issue)
    end

    it 'allows reporters to read, update, and admin issues' do
      expect_allowed(reporter, issue, :read_issue, :update_issue, :admin_issue)
      expect_allowed(reporter, issue_no_assignee, :read_issue, :update_issue, :admin_issue)
    end

    it 'allows reporters from group links to read, update, and admin issues' do
      expect_allowed(reporter_from_group_link, issue, :read_issue, :update_issue, :admin_issue)
      expect_allowed(reporter_from_group_link, issue_no_assignee, :read_issue, :update_issue, :admin_issue)
    end

    it 'allows issue authors to read and update their issues' do
      expect_allowed(author, issue, :read_issue, :update_issue)
      expect_disallowed(author, issue, :admin_issue)

      expect_allowed(author, issue_no_assignee, :read_issue)
      expect_disallowed(author, issue_no_assignee, :update_issue, :admin_issue)
    end

    it 'allows issue assignees to read and update their issues' do
      expect_allowed(assignee, issue, :read_issue, :update_issue)
      expect_disallowed(assignee, issue, :admin_issue)

      expect_allowed(assignee, issue_no_assignee, :read_issue)
      expect_disallowed(assignee, issue_no_assignee, :update_issue, :admin_issue)
    end

    context 'with confidential issues' do
      let(:confidential_issue) { create(:issue, :confidential, project: project, assignee: assignee, author: author) }
      let(:confidential_issue_no_assignee) { create(:issue, :confidential, project: project) }

      it 'does not allow guests to read confidential issues' do
        expect_disallowed(guest, confidential_issue, :read_issue, :update_issue, :admin_issue)
        expect_disallowed(guest, confidential_issue_no_assignee, :read_issue, :update_issue, :admin_issue)
      end

      it 'allows reporters to read, update, and admin confidential issues' do
        expect_allowed(reporter, confidential_issue, :read_issue, :update_issue, :admin_issue)
        expect_allowed(reporter, confidential_issue_no_assignee, :read_issue, :update_issue, :admin_issue)
      end

      it 'allows reporter from group links to read, update, and admin confidential issues' do
        expect_allowed(reporter_from_group_link, confidential_issue, :read_issue, :update_issue, :admin_issue)
        expect_allowed(reporter_from_group_link, confidential_issue_no_assignee, :read_issue, :update_issue, :admin_issue)
      end

      it 'allows issue authors to read and update their confidential issues' do
        expect_allowed(author, confidential_issue, :read_issue, :update_issue)
        expect_disallowed(author, confidential_issue, :admin_issue)

        expect_disallowed(author, confidential_issue_no_assignee, :read_issue, :update_issue, :admin_issue)
      end

      it 'allows issue assignees to read and update their confidential issues' do
        expect_allowed(assignee, confidential_issue, :read_issue, :update_issue)
        expect_disallowed(assignee, confidential_issue, :admin_issue)

        expect_disallowed(assignee, confidential_issue_no_assignee, :read_issue, :update_issue, :admin_issue)
      end
    end
  end
end
