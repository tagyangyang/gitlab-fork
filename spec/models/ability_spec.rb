require 'spec_helper'

describe Ability, lib: true do
  context 'using a nil subject' do
    it 'is always empty' do
      expect(Ability.policy_for(nil, nil)).to be_banned
    end
  end

  describe '.can_edit_note?' do
    let(:project) { create(:empty_project) }
    let(:note) { create(:note_on_issue, project: project) }

    context 'using an anonymous user' do
      it 'returns false' do
        expect(described_class.can_edit_note?(nil, note)).to be_falsy
      end
    end

    context 'using a system note' do
      it 'returns false' do
        system_note = create(:note, system: true)
        user = create(:user)

        expect(described_class.can_edit_note?(user, system_note)).to be_falsy
      end
    end

    context 'using users with different access levels' do
      let(:user) { create(:user) }

      it 'returns true for the author' do
        expect(described_class.can_edit_note?(note.author, note)).to be_truthy
      end

      it 'returns false for a guest user' do
        project.team << [user, :guest]

        expect(described_class.can_edit_note?(user, note)).to be_falsy
      end

      it 'returns false for a developer' do
        project.team << [user, :developer]

        expect(described_class.can_edit_note?(user, note)).to be_falsy
      end

      it 'returns true for a master' do
        project.team << [user, :master]

        expect(described_class.can_edit_note?(user, note)).to be_truthy
      end

      it 'returns true for a group owner' do
        group = create(:group)
        project.project_group_links.create(
          group: group,
          group_access: Gitlab::Access::MASTER)
        group.add_owner(user)

        expect(described_class.can_edit_note?(user, note)).to be_truthy
      end
    end
  end

  describe '.users_that_can_read_project' do
    context 'using a public project' do
      it 'returns all the users' do
        project = create(:empty_project, :public)
        user = build(:user)

        expect(described_class.users_that_can_read_project([user], project)).
          to eq([user])
      end
    end

    context 'using an internal project' do
      let(:project) { create(:empty_project, :internal) }

      it 'returns users that are administrators' do
        user = build(:user, admin: true)

        expect(described_class.users_that_can_read_project([user], project)).
          to eq([user])
      end

      it 'returns internal users while skipping external users' do
        user1 = build(:user)
        user2 = build(:user, external: true)
        users = [user1, user2]

        expect(described_class.users_that_can_read_project(users, project)).
          to eq([user1])
      end

      it 'returns external users if they are the project owner' do
        user1 = build(:user, external: true)
        user2 = build(:user, external: true)
        users = [user1, user2]

        expect(project).to receive(:owner).twice.and_return(user1)

        expect(described_class.users_that_can_read_project(users, project)).
          to eq([user1])
      end

      it 'returns external users if they are project members' do
        user1 = build(:user, external: true)
        user2 = build(:user, external: true)
        users = [user1, user2]

        expect(project.team).to receive(:members).twice.and_return([user1])

        expect(described_class.users_that_can_read_project(users, project)).
          to eq([user1])
      end

      it 'returns an empty Array if all users are external users without access' do
        user1 = build(:user, external: true)
        user2 = build(:user, external: true)
        users = [user1, user2]

        expect(described_class.users_that_can_read_project(users, project)).
          to eq([])
      end
    end

    context 'using a private project' do
      let(:project) { create(:empty_project, :private) }

      it 'returns users that are administrators' do
        user = build(:user, admin: true)

        expect(described_class.users_that_can_read_project([user], project)).
          to eq([user])
      end

      it 'returns external users if they are the project owner' do
        user1 = build(:user, external: true)
        user2 = build(:user, external: true)
        users = [user1, user2]

        expect(project).to receive(:owner).twice.and_return(user1)

        expect(described_class.users_that_can_read_project(users, project)).
          to eq([user1])
      end

      it 'returns external users if they are project members' do
        user1 = build(:user, external: true)
        user2 = build(:user, external: true)
        users = [user1, user2]

        expect(project.team).to receive(:members).twice.and_return([user1])

        expect(described_class.users_that_can_read_project(users, project)).
          to eq([user1])
      end

      it 'returns an empty Array if all users are internal users without access' do
        user1 = build(:user)
        user2 = build(:user)
        users = [user1, user2]

        expect(described_class.users_that_can_read_project(users, project)).
          to eq([])
      end

      it 'returns an empty Array if all users are external users without access' do
        user1 = build(:user, external: true)
        user2 = build(:user, external: true)
        users = [user1, user2]

        expect(described_class.users_that_can_read_project(users, project)).
          to eq([])
      end
    end
  end

  describe '.users_that_can_read_personal_snippet' do
    def users_for_snippet(snippet)
      described_class.users_that_can_read_personal_snippet(users, snippet)
    end

    let(:users)  { create_list(:user, 3) }
    let(:author) { users[0] }

    it 'private snippet is readable only by its author' do
      snippet = create(:personal_snippet, :private, author: author)

      expect(users_for_snippet(snippet)).to match_array([author])
    end

    it 'internal snippet is readable by all registered users' do
      snippet = create(:personal_snippet, :public, author: author)

      expect(users_for_snippet(snippet)).to match_array(users)
    end

    it 'public snippet is readable by all users' do
      snippet = create(:personal_snippet, :public, author: author)

      expect(users_for_snippet(snippet)).to match_array(users)
    end
  end

  describe '.issues_readable_by_user' do
    context 'with an admin user' do
      it 'returns all given issues' do
        user = build(:user, admin: true)
        issue = build(:issue)

        expect(described_class.issues_readable_by_user([issue], user)).
          to eq([issue])
      end
    end

    context 'with a regular user' do
      it 'returns the issues readable by the user' do
        user = build(:user)
        issue = build(:issue)

        expect(issue).to receive(:readable_by?).with(user).and_return(true)

        expect(described_class.issues_readable_by_user([issue], user)).
          to eq([issue])
      end

      it 'returns an empty Array when no issues are readable' do
        user = build(:user)
        issue = build(:issue)

        expect(issue).to receive(:readable_by?).with(user).and_return(false)

        expect(described_class.issues_readable_by_user([issue], user)).to eq([])
      end
    end

    context 'without a regular user' do
      it 'returns issues that are publicly visible' do
        hidden_issue = build(:issue)
        visible_issue = build(:issue)

        expect(hidden_issue).to receive(:publicly_visible?).and_return(false)
        expect(visible_issue).to receive(:publicly_visible?).and_return(true)

        issues = described_class.
          issues_readable_by_user([hidden_issue, visible_issue])

        expect(issues).to eq([visible_issue])
      end
    end
  end

  describe '.project_disabled_features_rules' do
    let(:project) { create(:empty_project, :wiki_disabled) }

    subject { described_class.policy_for(project.owner, project) }

    context 'wiki named abilities' do
      it 'disables wiki abilities if the project has no wiki' do
        expect(project).to receive(:has_external_wiki?).and_return(false)
        expect(subject).not_to be_allowed(:read_wiki)
        expect(subject).not_to be_allowed(:create_wiki)
        expect(subject).not_to be_allowed(:update_wiki)
        expect(subject).not_to be_allowed(:admin_wiki)
      end
    end
  end
end
