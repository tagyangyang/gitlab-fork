require 'spec_helper'

describe Users::MigrateToGhostUserService, services: true do
  let!(:user)      { create(:user) }
  let!(:project)   { create(:project) }
  let(:service)    { described_class.new(user) }

  context "migrating a user's associated records to the ghost user" do
    context 'issues'  do
      include_examples "migrating a deleted user's associated records to the ghost user", Issue do
        let(:created_record) { create(:issue, project: project, author: user) }
        let(:assigned_record) { create(:issue, project: project, assignee: user) }
      end
    end

    context 'merge requests' do
      include_examples "migrating a deleted user's associated records to the ghost user", MergeRequest do
        let(:created_record) { create(:merge_request, source_project: project, author: user, target_branch: "first") }
        let(:assigned_record) { create(:merge_request, source_project: project, assignee: user, target_branch: 'second') }
      end
    end

    context 'notes' do
      include_examples "migrating a deleted user's associated records to the ghost user", Note do
        let(:created_record) { create(:note, project: project, author: user) }
      end
    end

    context 'abuse reports' do
      include_examples "migrating a deleted user's associated records to the ghost user", AbuseReport do
        let(:created_record) { create(:abuse_report, reporter: user, user: create(:user)) }
      end
    end

    context 'award emoji' do
      include_examples "migrating a deleted user's associated records to the ghost user", AwardEmoji do
        let(:created_record) { create(:award_emoji, user: user) }
        let(:author_alias) { :user }

        context "when the awardable already has an award emoji of the same name assigned to the ghost user" do
          let(:awardable) { create(:issue) }
          let!(:existing_award_emoji) { create(:award_emoji, user: User.ghost, name: "thumbsup", awardable: awardable) }
          let!(:award_emoji) { create(:award_emoji, user: user, name: "thumbsup", awardable: awardable) }

          it "migrates the award emoji regardless" do
            service.execute

            migrated_record = AwardEmoji.find_by_id(award_emoji.id)

            expect(migrated_record.user).to eq(User.ghost)
          end

          it "does not leave the migrated award emoji in an invalid state" do
            service.execute

            migrated_record = AwardEmoji.find_by_id(award_emoji.id)

            expect(migrated_record).to be_valid
          end
        end
      end
    end
  end
end
