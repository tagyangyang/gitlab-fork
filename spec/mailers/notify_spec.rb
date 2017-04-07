require 'spec_helper'
require 'email_spec'

describe Notify do
  include EmailSpec::Helpers
  include EmailSpec::Matchers
  include RepoHelpers

  include_context 'gitlab email notification'

  def have_referable_subject(referable, reply: false)
    prefix = referable.project.name if referable.project
    prefix = "Re: #{prefix}" if reply

    suffix = "#{referable.title} (#{referable.to_reference})"

    have_subject [prefix, suffix].compact.join(' | ')
  end

  context 'for a project' do
    describe 'items that are assignable, the email' do
      let(:current_user) { create(:user, email: "current@email.com") }
      let(:assignee) { create(:user, email: 'assignee@example.com', name: 'John Doe') }
      let(:previous_assignee) { create(:user, name: 'Previous Assignee') }

      shared_examples 'an assignee email' do
        it 'is sent to the assignee as the author' do
          sender = subject.header[:from].addrs.first

          aggregate_failures do
            expect(sender.display_name).to eq(current_user.name)
            expect(sender.address).to eq(gitlab_sender)
            expect(subject).to deliver_to(assignee.email)
          end
        end
      end

      context 'for issues' do
        let(:issue) { create(:issue, author: current_user, assignee: assignee, project: project) }
        let(:issue_with_description) { create(:issue, author: current_user, assignee: assignee, project: project, description: 'My awesome description') }

        describe 'that are new' do
          subject { Notify.new_issue_email(issue.assignee_id, issue.id) }

          it_behaves_like 'an assignee email'
          it_behaves_like 'an email starting a new thread with reply-by-email enabled' do
            let(:model) { issue }
          end
          it_behaves_like 'it should show Gmail Actions View Issue link'
          it_behaves_like 'an unsubscribeable thread'

          it 'has the correct subject and body' do
            aggregate_failures do
              is_expected.to have_referable_subject(issue)
              is_expected.to have_body_text(namespace_project_issue_path(project.namespace, project, issue))
            end
          end

          context 'when enabled email_author_in_body' do
            before do
              stub_application_setting(email_author_in_body: true)
            end

            it 'contains a link to note author' do
              is_expected.to have_html_escaped_body_text(issue.author_name)
              is_expected.to have_body_text 'wrote:'
            end
          end
        end

        describe 'that are new with a description' do
          subject { Notify.new_issue_email(issue_with_description.assignee_id, issue_with_description.id) }

          it_behaves_like 'it should show Gmail Actions View Issue link'

          it 'contains the description' do
            is_expected.to have_html_escaped_body_text issue_with_description.description
          end
        end

        describe 'that have been reassigned' do
          subject { Notify.reassigned_issue_email(recipient.id, issue.id, previous_assignee.id, current_user.id) }

          it_behaves_like 'a multiple recipients email'
          it_behaves_like 'an answer to an existing thread with reply-by-email enabled' do
            let(:model) { issue }
          end
          it_behaves_like 'it should show Gmail Actions View Issue link'
          it_behaves_like 'an unsubscribeable thread'

          it 'is sent as the author' do
            sender = subject.header[:from].addrs[0]
            expect(sender.display_name).to eq(current_user.name)
            expect(sender.address).to eq(gitlab_sender)
          end

          it 'has the correct subject and body' do
            aggregate_failures do
              is_expected.to have_referable_subject(issue, reply: true)
              is_expected.to have_html_escaped_body_text(previous_assignee.name)
              is_expected.to have_html_escaped_body_text(assignee.name)
              is_expected.to have_body_text(namespace_project_issue_path(project.namespace, project, issue))
            end
          end
        end

        describe 'that have been relabeled' do
          subject { Notify.relabeled_issue_email(recipient.id, issue.id, %w[foo bar baz], current_user.id) }

          it_behaves_like 'a multiple recipients email'
          it_behaves_like 'an answer to an existing thread with reply-by-email enabled' do
            let(:model) { issue }
          end
          it_behaves_like 'it should show Gmail Actions View Issue link'
          it_behaves_like 'a user cannot unsubscribe through footer link'
          it_behaves_like 'an email with a labels subscriptions link in its footer'

          it 'is sent as the author' do
            sender = subject.header[:from].addrs[0]
            expect(sender.display_name).to eq(current_user.name)
            expect(sender.address).to eq(gitlab_sender)
          end

          it 'has the correct subject and body' do
            aggregate_failures do
              is_expected.to have_referable_subject(issue, reply: true)
              is_expected.to have_body_text('foo, bar, and baz')
              is_expected.to have_body_text(namespace_project_issue_path(project.namespace, project, issue))
            end
          end
        end

        describe 'status changed' do
          let(:status) { 'closed' }
          subject { Notify.issue_status_changed_email(recipient.id, issue.id, status, current_user.id) }

          it_behaves_like 'an answer to an existing thread with reply-by-email enabled' do
            let(:model) { issue }
          end
          it_behaves_like 'it should show Gmail Actions View Issue link'
          it_behaves_like 'an unsubscribeable thread'

          it 'is sent as the author' do
            sender = subject.header[:from].addrs[0]
            expect(sender.display_name).to eq(current_user.name)
            expect(sender.address).to eq(gitlab_sender)
          end

          it 'has the correct subject and body' do
            aggregate_failures do
              is_expected.to have_referable_subject(issue, reply: true)
              is_expected.to have_body_text(status)
              is_expected.to have_html_escaped_body_text(current_user.name)
              is_expected.to have_body_text(namespace_project_issue_path project.namespace, project, issue)
            end
          end
        end

        describe 'moved to another project' do
          let(:new_issue) { create(:issue) }
          subject { Notify.issue_moved_email(recipient, issue, new_issue, current_user) }

          it_behaves_like 'an answer to an existing thread with reply-by-email enabled' do
            let(:model) { issue }
          end
          it_behaves_like 'it should show Gmail Actions View Issue link'
          it_behaves_like 'an unsubscribeable thread'

          it 'contains description about action taken' do
            is_expected.to have_body_text 'Issue was moved to another project'
          end

          it 'has the correct subject and body' do
            new_issue_url = namespace_project_issue_path(new_issue.project.namespace,
                                                         new_issue.project, new_issue)

            aggregate_failures do
              is_expected.to have_referable_subject(issue, reply: true)
              is_expected.to have_body_text(new_issue_url)
              is_expected.to have_body_text(namespace_project_issue_path(project.namespace, project, issue))
            end
          end
        end
      end

      context 'for merge requests' do
        let(:project) { create(:project, :repository) }
        let(:merge_author) { create(:user) }
        let(:merge_request) { create(:merge_request, author: current_user, assignee: assignee, source_project: project, target_project: project) }
        let(:merge_request_with_description) { create(:merge_request, author: current_user, assignee: assignee, source_project: project, target_project: project, description: 'My awesome description') }

        describe 'that are new' do
          subject { Notify.new_merge_request_email(merge_request.assignee_id, merge_request.id) }

          it_behaves_like 'an assignee email'
          it_behaves_like 'an email starting a new thread with reply-by-email enabled' do
            let(:model) { merge_request }
          end
          it_behaves_like 'it should show Gmail Actions View Merge request link'
          it_behaves_like 'an unsubscribeable thread'

          it 'has the correct subject and body' do
            aggregate_failures do
              is_expected.to have_referable_subject(merge_request)
              is_expected.to have_body_text(namespace_project_merge_request_path(project.namespace, project, merge_request))
              is_expected.to have_body_text(merge_request.source_branch)
              is_expected.to have_body_text(merge_request.target_branch)
            end
          end

          context 'when enabled email_author_in_body' do
            before do
              stub_application_setting(email_author_in_body: true)
            end

            it 'contains a link to note author' do
              is_expected.to have_html_escaped_body_text merge_request.author_name
              is_expected.to have_body_text 'wrote:'
            end
          end
        end

        describe 'that are new with a description' do
          subject { Notify.new_merge_request_email(merge_request_with_description.assignee_id, merge_request_with_description.id) }

          it_behaves_like 'it should show Gmail Actions View Merge request link'
          it_behaves_like "an unsubscribeable thread"

          it 'contains the description' do
            is_expected.to have_html_escaped_body_text merge_request_with_description.description
          end
        end

        describe 'that are reassigned' do
          subject { Notify.reassigned_merge_request_email(recipient.id, merge_request.id, previous_assignee.id, current_user.id) }

          it_behaves_like 'a multiple recipients email'
          it_behaves_like 'an answer to an existing thread with reply-by-email enabled' do
            let(:model) { merge_request }
          end
          it_behaves_like 'it should show Gmail Actions View Merge request link'
          it_behaves_like "an unsubscribeable thread"

          it 'is sent as the author' do
            sender = subject.header[:from].addrs[0]
            expect(sender.display_name).to eq(current_user.name)
            expect(sender.address).to eq(gitlab_sender)
          end

          it 'has the correct subject and body' do
            aggregate_failures do
              is_expected.to have_referable_subject(merge_request, reply: true)
              is_expected.to have_html_escaped_body_text(previous_assignee.name)
              is_expected.to have_body_text(namespace_project_merge_request_path(project.namespace, project, merge_request))
              is_expected.to have_html_escaped_body_text(assignee.name)
            end
          end
        end

        describe 'that have been relabeled' do
          subject { Notify.relabeled_merge_request_email(recipient.id, merge_request.id, %w[foo bar baz], current_user.id) }

          it_behaves_like 'a multiple recipients email'
          it_behaves_like 'an answer to an existing thread with reply-by-email enabled' do
            let(:model) { merge_request }
          end
          it_behaves_like 'it should show Gmail Actions View Merge request link'
          it_behaves_like 'a user cannot unsubscribe through footer link'
          it_behaves_like 'an email with a labels subscriptions link in its footer'

          it 'is sent as the author' do
            sender = subject.header[:from].addrs[0]
            expect(sender.display_name).to eq(current_user.name)
            expect(sender.address).to eq(gitlab_sender)
          end

          it 'has the correct subject and body' do
            is_expected.to have_referable_subject(merge_request, reply: true)
            is_expected.to have_body_text('foo, bar, and baz')
            is_expected.to have_body_text(namespace_project_merge_request_path(project.namespace, project, merge_request))
          end
        end

        describe 'status changed' do
          let(:status) { 'reopened' }
          subject { Notify.merge_request_status_email(recipient.id, merge_request.id, status, current_user.id) }

          it_behaves_like 'an answer to an existing thread with reply-by-email enabled' do
            let(:model) { merge_request }
          end
          it_behaves_like 'it should show Gmail Actions View Merge request link'
          it_behaves_like 'an unsubscribeable thread'

          it 'is sent as the author' do
            sender = subject.header[:from].addrs[0]
            expect(sender.display_name).to eq(current_user.name)
            expect(sender.address).to eq(gitlab_sender)
          end

          it 'has the correct subject and body' do
            aggregate_failures do
              is_expected.to have_referable_subject(merge_request, reply: true)
              is_expected.to have_body_text(status)
              is_expected.to have_html_escaped_body_text(current_user.name)
              is_expected.to have_body_text(namespace_project_merge_request_path(project.namespace, project, merge_request))
            end
          end
        end

        describe 'that are merged' do
          subject { Notify.merged_merge_request_email(recipient.id, merge_request.id, merge_author.id) }

          it_behaves_like 'a multiple recipients email'
          it_behaves_like 'an answer to an existing thread with reply-by-email enabled' do
            let(:model) { merge_request }
          end
          it_behaves_like 'it should show Gmail Actions View Merge request link'
          it_behaves_like 'an unsubscribeable thread'

          it 'is sent as the merge author' do
            sender = subject.header[:from].addrs[0]
            expect(sender.display_name).to eq(merge_author.name)
            expect(sender.address).to eq(gitlab_sender)
          end

          it 'has the correct subject and body' do
            aggregate_failures do
              is_expected.to have_referable_subject(merge_request, reply: true)
              is_expected.to have_body_text('merged')
              is_expected.to have_body_text(namespace_project_merge_request_path(project.namespace, project, merge_request))
            end
          end
        end
      end
    end

    describe 'project was moved' do
      let(:project) { create(:empty_project) }
      let(:user) { create(:user) }
      subject { Notify.project_was_moved_email(project.id, user.id, "gitlab/gitlab") }

      it_behaves_like 'an email sent from GitLab'
      it_behaves_like 'it should not have Gmail Actions links'
      it_behaves_like "a user cannot unsubscribe through footer link"

      it 'has the correct subject and body' do
        is_expected.to have_subject("#{project.name} | Project was moved")
        is_expected.to have_html_escaped_body_text project.name_with_namespace
        is_expected.to have_body_text(project.ssh_url_to_repo)
      end
    end

    describe 'project access requested' do
      context 'for a project in a user namespace' do
        let(:project) do
          create(:empty_project, :public, :access_requestable) do |project|
            project.team << [project.owner, :master, project.owner]
          end
        end

        let(:user) { create(:user) }
        let(:project_member) do
          project.request_access(user)
          project.requesters.find_by(user_id: user.id)
        end
        subject { Notify.member_access_requested_email('project', project_member.id) }

        it_behaves_like 'an email sent from GitLab'
        it_behaves_like 'it should not have Gmail Actions links'
        it_behaves_like "a user cannot unsubscribe through footer link"

        it 'contains all the useful information' do
          to_emails = subject.header[:to].addrs
          expect(to_emails.size).to eq(1)
          expect(to_emails[0].address).to eq(project.members.owners_and_masters.first.user.notification_email)

          is_expected.to have_subject "Request to join the #{project.name_with_namespace} project"
          is_expected.to have_html_escaped_body_text project.name_with_namespace
          is_expected.to have_body_text namespace_project_project_members_url(project.namespace, project)
          is_expected.to have_body_text project_member.human_access
        end
      end

      context 'for a project in a group' do
        let(:group_owner) { create(:user) }
        let(:group) { create(:group).tap { |g| g.add_owner(group_owner) } }
        let(:project) { create(:empty_project, :public, :access_requestable, namespace: group) }
        let(:user) { create(:user) }
        let(:project_member) do
          project.request_access(user)
          project.requesters.find_by(user_id: user.id)
        end
        subject { Notify.member_access_requested_email('project', project_member.id) }

        it_behaves_like 'an email sent from GitLab'
        it_behaves_like 'it should not have Gmail Actions links'
        it_behaves_like "a user cannot unsubscribe through footer link"

        it 'contains all the useful information' do
          to_emails = subject.header[:to].addrs
          expect(to_emails.size).to eq(1)
          expect(to_emails[0].address).to eq(group.members.owners_and_masters.first.user.notification_email)

          is_expected.to have_subject "Request to join the #{project.name_with_namespace} project"
          is_expected.to have_html_escaped_body_text project.name_with_namespace
          is_expected.to have_body_text namespace_project_project_members_url(project.namespace, project)
          is_expected.to have_body_text project_member.human_access
        end
      end
    end

    describe 'project access denied' do
      let(:project) { create(:empty_project, :public, :access_requestable) }
      let(:user) { create(:user) }
      let(:project_member) do
        project.request_access(user)
        project.requesters.find_by(user_id: user.id)
      end
      subject { Notify.member_access_denied_email('project', project.id, user.id) }

      it_behaves_like 'an email sent from GitLab'
      it_behaves_like 'it should not have Gmail Actions links'
      it_behaves_like "a user cannot unsubscribe through footer link"

      it 'contains all the useful information' do
        is_expected.to have_subject "Access to the #{project.name_with_namespace} project was denied"
        is_expected.to have_html_escaped_body_text project.name_with_namespace
        is_expected.to have_body_text project.web_url
      end
    end

    describe 'project access changed' do
      let(:owner) { create(:user, name: "Chang O'Keefe") }
      let(:project) { create(:empty_project, :public, :access_requestable, namespace: owner.namespace) }
      let(:user) { create(:user) }
      let(:project_member) { create(:project_member, project: project, user: user) }
      subject { Notify.member_access_granted_email('project', project_member.id) }

      it_behaves_like 'an email sent from GitLab'
      it_behaves_like 'it should not have Gmail Actions links'
      it_behaves_like "a user cannot unsubscribe through footer link"

      it 'contains all the useful information' do
        is_expected.to have_subject "Access to the #{project.name_with_namespace} project was granted"
        is_expected.to have_html_escaped_body_text project.name_with_namespace
        is_expected.to have_body_text project.web_url
        is_expected.to have_body_text project_member.human_access
      end
    end

    def invite_to_project(project, inviter:)
      create(
        :project_member,
        :developer,
        project: project,
        invite_token: '1234',
        invite_email: 'toto@example.com',
        user: nil,
        created_by: inviter
      )
    end

    describe 'project invitation' do
      let(:project) { create(:empty_project) }
      let(:master) { create(:user).tap { |u| project.team << [u, :master] } }
      let(:project_member) { invite_to_project(project, inviter: master) }

      subject { Notify.member_invited_email('project', project_member.id, project_member.invite_token) }

      it_behaves_like 'an email sent from GitLab'
      it_behaves_like 'it should not have Gmail Actions links'
      it_behaves_like "a user cannot unsubscribe through footer link"

      it 'contains all the useful information' do
        is_expected.to have_subject "Invitation to join the #{project.name_with_namespace} project"
        is_expected.to have_html_escaped_body_text project.name_with_namespace
        is_expected.to have_body_text project.web_url
        is_expected.to have_body_text project_member.human_access
        is_expected.to have_body_text project_member.invite_token
      end
    end

    describe 'project invitation accepted' do
      let(:project) { create(:empty_project) }
      let(:invited_user) { create(:user, name: 'invited user') }
      let(:master) { create(:user).tap { |u| project.team << [u, :master] } }
      let(:project_member) do
        invitee = invite_to_project(project, inviter: master)
        invitee.accept_invite!(invited_user)
        invitee
      end

      subject { Notify.member_invite_accepted_email('project', project_member.id) }

      it_behaves_like 'an email sent from GitLab'
      it_behaves_like 'it should not have Gmail Actions links'
      it_behaves_like "a user cannot unsubscribe through footer link"

      it 'contains all the useful information' do
        is_expected.to have_subject 'Invitation accepted'
        is_expected.to have_html_escaped_body_text project.name_with_namespace
        is_expected.to have_body_text project.web_url
        is_expected.to have_body_text project_member.invite_email
        is_expected.to have_html_escaped_body_text invited_user.name
      end
    end

    describe 'project invitation declined' do
      let(:project) { create(:empty_project) }
      let(:master) { create(:user).tap { |u| project.team << [u, :master] } }
      let(:project_member) do
        invitee = invite_to_project(project, inviter: master)
        invitee.decline_invite!
        invitee
      end

      subject { Notify.member_invite_declined_email('project', project.id, project_member.invite_email, master.id) }

      it_behaves_like 'an email sent from GitLab'
      it_behaves_like 'it should not have Gmail Actions links'
      it_behaves_like "a user cannot unsubscribe through footer link"

      it 'contains all the useful information' do
        is_expected.to have_subject 'Invitation declined'
        is_expected.to have_html_escaped_body_text project.name_with_namespace
        is_expected.to have_body_text project.web_url
        is_expected.to have_body_text project_member.invite_email
      end
    end

    context 'items that are noteable, the email for a note' do
      let(:note_author) { create(:user, name: 'author_name') }
      let(:note) { create(:note, project: project, author: note_author) }

      before :each do
        allow(Note).to receive(:find).with(note.id).and_return(note)
      end

      shared_examples 'a note email' do
        it_behaves_like 'it should have Gmail Actions links'

        it 'is sent to the given recipient as the author' do
          sender = subject.header[:from].addrs[0]

          aggregate_failures do
            expect(sender.display_name).to eq(note_author.name)
            expect(sender.address).to eq(gitlab_sender)
            expect(subject).to deliver_to(recipient.notification_email)
          end
        end

        it 'contains the message from the note' do
          is_expected.to have_html_escaped_body_text note.note
        end

        it 'does not contain note author' do
          is_expected.not_to have_body_text 'wrote:'
        end

        context 'when enabled email_author_in_body' do
          before do
            stub_application_setting(email_author_in_body: true)
          end

          it 'contains a link to note author' do
            is_expected.to have_html_escaped_body_text note.author_name
            is_expected.to have_body_text 'wrote:'
          end
        end
      end

      describe 'on a commit' do
        let(:project) { create(:project, :repository) }
        let(:commit) { project.commit }

        before(:each) { allow(note).to receive(:noteable).and_return(commit) }

        subject { Notify.note_commit_email(recipient.id, note.id) }

        it_behaves_like 'a note email'
        it_behaves_like 'an answer to an existing thread with reply-by-email enabled' do
          let(:model) { commit }
        end
        it_behaves_like 'it should show Gmail Actions View Commit link'
        it_behaves_like 'a user cannot unsubscribe through footer link'

        it 'has the correct subject and body' do
          aggregate_failures do
            is_expected.to have_subject("Re: #{project.name} | #{commit.title.strip} (#{commit.short_id})")
            is_expected.to have_body_text(commit.short_id)
          end
        end
      end

      describe 'on a merge request' do
        let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
        let(:note_on_merge_request_path) { namespace_project_merge_request_path(project.namespace, project, merge_request, anchor: "note_#{note.id}") }
        before(:each) { allow(note).to receive(:noteable).and_return(merge_request) }

        subject { Notify.note_merge_request_email(recipient.id, note.id) }

        it_behaves_like 'a note email'
        it_behaves_like 'an answer to an existing thread with reply-by-email enabled' do
          let(:model) { merge_request }
        end
        it_behaves_like 'it should show Gmail Actions View Merge request link'
        it_behaves_like 'an unsubscribeable thread'

        it 'has the correct subject and body' do
          aggregate_failures do
            is_expected.to have_referable_subject(merge_request, reply: true)
            is_expected.to have_body_text note_on_merge_request_path
          end
        end
      end

      describe 'on an issue' do
        let(:issue) { create(:issue, project: project) }
        let(:note_on_issue_path) { namespace_project_issue_path(project.namespace, project, issue, anchor: "note_#{note.id}") }
        before(:each) { allow(note).to receive(:noteable).and_return(issue) }

        subject { Notify.note_issue_email(recipient.id, note.id) }

        it_behaves_like 'a note email'
        it_behaves_like 'an answer to an existing thread with reply-by-email enabled' do
          let(:model) { issue }
        end
        it_behaves_like 'it should show Gmail Actions View Issue link'
        it_behaves_like 'an unsubscribeable thread'

        it 'has the correct subject and body' do
          aggregate_failures do
            is_expected.to have_referable_subject(issue, reply: true)
            is_expected.to have_body_text(note_on_issue_path)
          end
        end
      end
    end

    context 'items that are noteable, emails for a note on a diff' do
      let(:project) { create(:project, :repository) }
      let(:note_author) { create(:user, name: 'author_name') }

      before :each do
        allow(Note).to receive(:find).with(note.id).and_return(note)
      end

      shared_examples 'a note email on a diff' do  |model|
        let(:note) { create(model, project: project, author: note_author) }

        it "includes diffs with character-level highlighting" do
          is_expected.to have_body_text '<span class="p">}</span></span>'
        end

        it 'contains a link to the diff file' do
          is_expected.to have_body_text note.diff_file.file_path
        end

        it_behaves_like 'it should have Gmail Actions links'

        it 'is sent to the given recipient as the author' do
          sender = subject.header[:from].addrs[0]

          aggregate_failures do
            expect(sender.display_name).to eq(note_author.name)
            expect(sender.address).to eq(gitlab_sender)
            expect(subject).to deliver_to(recipient.notification_email)
          end
        end

        it 'contains the message from the note' do
          is_expected.to have_html_escaped_body_text note.note
        end

        it 'does not contain note author' do
          is_expected.not_to have_body_text 'wrote:'
        end

        context 'when enabled email_author_in_body' do
          before do
            stub_application_setting(email_author_in_body: true)
          end

          it 'contains a link to note author' do
            is_expected.to have_html_escaped_body_text note.author_name
            is_expected.to have_body_text 'wrote:'
          end
        end
      end

      describe 'on a commit' do
        let(:commit) { project.commit }
        let(:note) { create(:diff_note_on_commit) }

        subject { Notify.note_commit_email(recipient.id, note.id) }

        it_behaves_like 'a note email on a diff', :diff_note_on_commit
        it_behaves_like 'it should show Gmail Actions View Commit link'
        it_behaves_like 'a user cannot unsubscribe through footer link'
      end

      describe 'on a merge request' do
        let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
        let(:note) { create(:diff_note_on_merge_request) }

        subject { Notify.note_merge_request_email(recipient.id, note.id) }

        it_behaves_like 'a note email on a diff', :diff_note_on_merge_request
        it_behaves_like 'it should show Gmail Actions View Merge request link'
        it_behaves_like 'an unsubscribeable thread'
      end
    end
  end

  context 'for a group' do
    describe 'group access requested' do
      let(:group) { create(:group, :public, :access_requestable) }
      let(:user) { create(:user) }
      let(:group_member) do
        group.request_access(user)
        group.requesters.find_by(user_id: user.id)
      end
      subject { Notify.member_access_requested_email('group', group_member.id) }

      it_behaves_like 'an email sent from GitLab'
      it_behaves_like 'it should not have Gmail Actions links'
      it_behaves_like "a user cannot unsubscribe through footer link"

      it 'contains all the useful information' do
        is_expected.to have_subject "Request to join the #{group.name} group"
        is_expected.to have_html_escaped_body_text group.name
        is_expected.to have_body_text group_group_members_url(group)
        is_expected.to have_body_text group_member.human_access
      end
    end

    describe 'group access denied' do
      let(:group) { create(:group) }
      let(:user) { create(:user) }
      let(:group_member) do
        group.request_access(user)
        group.requesters.find_by(user_id: user.id)
      end
      subject { Notify.member_access_denied_email('group', group.id, user.id) }

      it_behaves_like 'an email sent from GitLab'
      it_behaves_like 'it should not have Gmail Actions links'
      it_behaves_like "a user cannot unsubscribe through footer link"

      it 'contains all the useful information' do
        is_expected.to have_subject "Access to the #{group.name} group was denied"
        is_expected.to have_html_escaped_body_text group.name
        is_expected.to have_body_text group.web_url
      end
    end

    describe 'group access changed' do
      let(:group) { create(:group) }
      let(:user) { create(:user) }
      let(:group_member) { create(:group_member, group: group, user: user) }

      subject { Notify.member_access_granted_email('group', group_member.id) }

      it_behaves_like 'an email sent from GitLab'
      it_behaves_like 'it should not have Gmail Actions links'
      it_behaves_like "a user cannot unsubscribe through footer link"

      it 'contains all the useful information' do
        is_expected.to have_subject "Access to the #{group.name} group was granted"
        is_expected.to have_html_escaped_body_text group.name
        is_expected.to have_body_text group.web_url
        is_expected.to have_body_text group_member.human_access
      end
    end

    def invite_to_group(group, inviter:)
      create(
        :group_member,
        :developer,
        group: group,
        invite_token: '1234',
        invite_email: 'toto@example.com',
        user: nil,
        created_by: inviter
      )
    end

    describe 'group invitation' do
      let(:group) { create(:group) }
      let(:owner) { create(:user).tap { |u| group.add_user(u, Gitlab::Access::OWNER) } }
      let(:group_member) { invite_to_group(group, inviter: owner) }

      subject { Notify.member_invited_email('group', group_member.id, group_member.invite_token) }

      it_behaves_like 'an email sent from GitLab'
      it_behaves_like 'it should not have Gmail Actions links'
      it_behaves_like "a user cannot unsubscribe through footer link"

      it 'contains all the useful information' do
        is_expected.to have_subject "Invitation to join the #{group.name} group"
        is_expected.to have_html_escaped_body_text group.name
        is_expected.to have_body_text group.web_url
        is_expected.to have_body_text group_member.human_access
        is_expected.to have_body_text group_member.invite_token
      end
    end

    describe 'group invitation accepted' do
      let(:group) { create(:group) }
      let(:invited_user) { create(:user, name: 'invited user') }
      let(:owner) { create(:user).tap { |u| group.add_user(u, Gitlab::Access::OWNER) } }
      let(:group_member) do
        invitee = invite_to_group(group, inviter: owner)
        invitee.accept_invite!(invited_user)
        invitee
      end

      subject { Notify.member_invite_accepted_email('group', group_member.id) }

      it_behaves_like 'an email sent from GitLab'
      it_behaves_like 'it should not have Gmail Actions links'
      it_behaves_like "a user cannot unsubscribe through footer link"

      it 'contains all the useful information' do
        is_expected.to have_subject 'Invitation accepted'
        is_expected.to have_html_escaped_body_text group.name
        is_expected.to have_body_text group.web_url
        is_expected.to have_body_text group_member.invite_email
        is_expected.to have_html_escaped_body_text invited_user.name
      end
    end

    describe 'group invitation declined' do
      let(:group) { create(:group) }
      let(:owner) { create(:user).tap { |u| group.add_user(u, Gitlab::Access::OWNER) } }
      let(:group_member) do
        invitee = invite_to_group(group, inviter: owner)
        invitee.decline_invite!
        invitee
      end

      subject { Notify.member_invite_declined_email('group', group.id, group_member.invite_email, owner.id) }

      it_behaves_like 'an email sent from GitLab'
      it_behaves_like 'it should not have Gmail Actions links'
      it_behaves_like "a user cannot unsubscribe through footer link"

      it 'contains all the useful information' do
        is_expected.to have_subject 'Invitation declined'
        is_expected.to have_html_escaped_body_text group.name
        is_expected.to have_body_text group.web_url
        is_expected.to have_body_text group_member.invite_email
      end
    end
  end

  describe 'confirmation if email changed' do
    let(:example_site_path) { root_path }
    let(:user) { create(:user, email: 'old-email@mail.com') }

    before do
      stub_config_setting(email_subject_suffix: 'A Nice Suffix')
      perform_enqueued_jobs do
        user.email = "new-email@mail.com"
        user.save
      end
    end

    subject { ActionMailer::Base.deliveries.last }

    it_behaves_like 'an email sent from GitLab'
    it_behaves_like "a user cannot unsubscribe through footer link"

    it 'is sent to the new user' do
      is_expected.to deliver_to 'new-email@mail.com'
    end

    it 'has the correct subject and body' do
      aggregate_failures do
        is_expected.to have_subject('Confirmation instructions | A Nice Suffix')
        is_expected.to have_body_text(example_site_path)
      end
    end
  end

  describe 'email on push for a created branch' do
    let(:example_site_path) { root_path }
    let(:user) { create(:user) }
    let(:tree_path) { namespace_project_tree_path(project.namespace, project, "empty-branch") }

    subject { Notify.repository_push_email(project.id, author_id: user.id, ref: 'refs/heads/empty-branch', action: :create) }

    it_behaves_like 'it should not have Gmail Actions links'
    it_behaves_like 'a user cannot unsubscribe through footer link'
    it_behaves_like 'an email with X-GitLab headers containing project details'
    it_behaves_like 'an email that contains a header with author username'

    it 'is sent as the author' do
      sender = subject.header[:from].addrs[0]
      expect(sender.display_name).to eq(user.name)
      expect(sender.address).to eq(gitlab_sender)
    end

    it 'has the correct subject and body' do
      aggregate_failures do
        is_expected.to have_subject("[Git][#{project.full_path}] Pushed new branch empty-branch")
        is_expected.to have_body_text(tree_path)
      end
    end
  end

  describe 'email on push for a created tag' do
    let(:example_site_path) { root_path }
    let(:user) { create(:user) }
    let(:tree_path) { namespace_project_tree_path(project.namespace, project, "v1.0") }

    subject { Notify.repository_push_email(project.id, author_id: user.id, ref: 'refs/tags/v1.0', action: :create) }

    it_behaves_like 'it should not have Gmail Actions links'
    it_behaves_like "a user cannot unsubscribe through footer link"
    it_behaves_like 'an email with X-GitLab headers containing project details'
    it_behaves_like 'an email that contains a header with author username'

    it 'is sent as the author' do
      sender = subject.header[:from].addrs[0]
      expect(sender.display_name).to eq(user.name)
      expect(sender.address).to eq(gitlab_sender)
    end

    it 'has the correct subject and body' do
      aggregate_failures do
        is_expected.to have_subject("[Git][#{project.full_path}] Pushed new tag v1.0")
        is_expected.to have_body_text(tree_path)
      end
    end
  end

  describe 'email on push for a deleted branch' do
    let(:example_site_path) { root_path }
    let(:user) { create(:user) }

    subject { Notify.repository_push_email(project.id, author_id: user.id, ref: 'refs/heads/master', action: :delete) }

    it_behaves_like 'it should not have Gmail Actions links'
    it_behaves_like 'a user cannot unsubscribe through footer link'
    it_behaves_like 'an email with X-GitLab headers containing project details'
    it_behaves_like 'an email that contains a header with author username'

    it 'is sent as the author' do
      sender = subject.header[:from].addrs[0]
      expect(sender.display_name).to eq(user.name)
      expect(sender.address).to eq(gitlab_sender)
    end

    it 'has the correct subject' do
      is_expected.to have_subject "[Git][#{project.full_path}] Deleted branch master"
    end
  end

  describe 'email on push for a deleted tag' do
    let(:example_site_path) { root_path }
    let(:user) { create(:user) }

    subject { Notify.repository_push_email(project.id, author_id: user.id, ref: 'refs/tags/v1.0', action: :delete) }

    it_behaves_like 'it should not have Gmail Actions links'
    it_behaves_like 'a user cannot unsubscribe through footer link'
    it_behaves_like 'an email with X-GitLab headers containing project details'
    it_behaves_like 'an email that contains a header with author username'

    it 'is sent as the author' do
      sender = subject.header[:from].addrs[0]
      expect(sender.display_name).to eq(user.name)
      expect(sender.address).to eq(gitlab_sender)
    end

    it 'has the correct subject' do
      is_expected.to have_subject "[Git][#{project.full_path}] Deleted tag v1.0"
    end
  end

  describe 'email on push with multiple commits' do
    let(:project) { create(:project, :repository) }
    let(:example_site_path) { root_path }
    let(:user) { create(:user) }
    let(:raw_compare) { Gitlab::Git::Compare.new(project.repository.raw_repository, sample_image_commit.id, sample_commit.id) }
    let(:compare) { Compare.decorate(raw_compare, project) }
    let(:commits) { compare.commits }
    let(:diff_path) { namespace_project_compare_path(project.namespace, project, from: Commit.new(compare.base, project), to: Commit.new(compare.head, project)) }
    let(:send_from_committer_email) { false }
    let(:diff_refs) { Gitlab::Diff::DiffRefs.new(base_sha: project.merge_base_commit(sample_image_commit.id, sample_commit.id).id, head_sha: sample_commit.id) }

    subject { Notify.repository_push_email(project.id, author_id: user.id, ref: 'refs/heads/master', action: :push, compare: compare, reverse_compare: false, diff_refs: diff_refs, send_from_committer_email: send_from_committer_email) }

    it_behaves_like 'it should not have Gmail Actions links'
    it_behaves_like 'a user cannot unsubscribe through footer link'
    it_behaves_like 'an email with X-GitLab headers containing project details'
    it_behaves_like 'an email that contains a header with author username'

    it 'is sent as the author' do
      sender = subject.header[:from].addrs[0]
      expect(sender.display_name).to eq(user.name)
      expect(sender.address).to eq(gitlab_sender)
    end

    it 'has the correct subject and body' do
      aggregate_failures do
        is_expected.to have_subject("[Git][#{project.full_path}][master] #{commits.length} commits: Ruby files modified")
        is_expected.to have_body_text('Change some files')
        is_expected.to have_body_text('def</span> <span class="nf">archive_formats_regex')
        is_expected.to have_body_text(diff_path)
        is_expected.not_to have_body_text('you are a member of')
      end
    end

    context "when set to send from committer email if domain matches" do
      let(:send_from_committer_email) { true }

      before do
        allow(Gitlab.config.gitlab).to receive(:host).and_return("gitlab.corp.company.com")
      end

      context "when the committer email domain is within the GitLab domain" do
        before do
          user.update_attribute(:email, "user@company.com")
          user.confirm
        end

        it "is sent from the committer email" do
          from  = subject.header[:from].addrs.first
          reply = subject.header[:reply_to].addrs.first

          aggregate_failures do
            expect(from.address).to eq(user.email)
            expect(reply.address).to eq(user.email)
          end
        end
      end

      context "when the committer email domain is not completely within the GitLab domain" do
        before do
          user.update_attribute(:email, "user@something.company.com")
          user.confirm
        end

        it "is sent from the default email" do
          from  = subject.header[:from].addrs.first
          reply = subject.header[:reply_to].addrs.first

          aggregate_failures do
            expect(from.address).to eq(gitlab_sender)
            expect(reply.address).to eq(gitlab_sender_reply_to)
          end
        end
      end

      context "when the committer email domain is outside the GitLab domain" do
        before do
          user.update_attribute(:email, "user@mpany.com")
          user.confirm
        end

        it "is sent from the default email" do
          from = subject.header[:from].addrs.first
          reply = subject.header[:reply_to].addrs.first

          aggregate_failures do
            expect(from.address).to eq(gitlab_sender)
            expect(reply.address).to eq(gitlab_sender_reply_to)
          end
        end
      end
    end
  end

  describe 'email on push with a single commit' do
    let(:project) { create(:project, :repository) }
    let(:example_site_path) { root_path }
    let(:user) { create(:user) }
    let(:raw_compare) { Gitlab::Git::Compare.new(project.repository.raw_repository, sample_commit.parent_id, sample_commit.id) }
    let(:compare) { Compare.decorate(raw_compare, project) }
    let(:commits) { compare.commits }
    let(:diff_path) { namespace_project_commit_path(project.namespace, project, commits.first) }
    let(:diff_refs) { Gitlab::Diff::DiffRefs.new(base_sha: project.merge_base_commit(sample_image_commit.id, sample_commit.id).id, head_sha: sample_commit.id) }

    subject { Notify.repository_push_email(project.id, author_id: user.id, ref: 'refs/heads/master', action: :push, compare: compare, diff_refs: diff_refs) }

    it_behaves_like 'it should show Gmail Actions View Commit link'
    it_behaves_like 'a user cannot unsubscribe through footer link'
    it_behaves_like 'an email with X-GitLab headers containing project details'
    it_behaves_like 'an email that contains a header with author username'

    it 'is sent as the author' do
      sender = subject.header[:from].addrs[0]
      expect(sender.display_name).to eq(user.name)
      expect(sender.address).to eq(gitlab_sender)
    end

    it 'has the correct subject and body' do
      aggregate_failures do
        is_expected.to have_subject("[Git][#{project.full_path}][master] #{commits.first.title}")
        is_expected.to have_body_text('Change some files')
        is_expected.to have_body_text('def</span> <span class="nf">archive_formats_regex')
        is_expected.to have_body_text(diff_path)
      end
    end
  end

  describe 'HTML emails setting' do
    let(:project) { create(:empty_project) }
    let(:user) { create(:user) }
    let(:multipart_mail) { Notify.project_was_moved_email(project.id, user.id, "gitlab/gitlab") }

    context 'when disabled' do
      it 'only sends the text template' do
        stub_application_setting(html_emails_enabled: false)

        EmailTemplateInterceptor.delivering_email(multipart_mail)

        expect(multipart_mail).to have_part_with('text/plain')
        expect(multipart_mail).not_to have_part_with('text/html')
      end
    end

    context 'when enabled' do
      it 'sends a multipart message' do
        stub_application_setting(html_emails_enabled: true)

        EmailTemplateInterceptor.delivering_email(multipart_mail)

        expect(multipart_mail).to have_part_with('text/plain')
        expect(multipart_mail).to have_part_with('text/html')
      end
    end

    matcher :have_part_with do |expected|
      match do |actual|
        actual.body.parts.any? { |part| part.content_type.try(:match, %r(#{expected})) }
      end
    end
  end
end
