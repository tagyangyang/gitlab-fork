require 'spec_helper'

describe IssuePolicy, models: true do
  let(:user) { create(:user) }

  describe '#rules' do
    context 'using a regular issue' do
      let(:project) { create(:empty_project, :public) }
      let(:issue) { create(:issue, project: project) }
      let(:policy) { described_class.new(user, issue) }

      context 'with a regular user' do
        it 'includes the read_issue permission' do
          expect(policy).to be_allowed(:read_issue)
        end

        it 'does not include the admin_issue permission' do
          expect(policy).not_to be_allowed(:admin_issue)
        end

        it 'does not include the update_issue permission' do
          expect(policy).not_to be_allowed(:update_issue)
        end
      end

      context 'with a user that is a project reporter' do
        before do
          project.team << [user, :reporter]
        end

        it 'includes the read_issue permission' do
          expect(policy).to be_allowed(:read_issue)
        end

        it 'includes the admin_issue permission' do
          expect(policy).to be_allowed(:admin_issue)
        end

        it 'includes the update_issue permission' do
          expect(policy).to be_allowed(:update_issue)
        end
      end

      context 'with a user that is a project guest' do
        before do
          project.team << [user, :guest]
        end

        it 'includes the read_issue permission' do
          expect(policy).to be_allowed(:read_issue)
        end

        it 'does not include the admin_issue permission' do
          expect(policy).not_to be_allowed(:admin_issue)
        end

        it 'does not include the update_issue permission' do
          expect(policy).not_to be_allowed(:update_issue)
        end
      end
    end

    context 'using a confidential issue' do
      let(:issue) { create(:issue, :confidential) }

      context 'with a regular user' do
        let(:policy) { described_class.new(user, issue) }

        it 'does not include the read_issue permission' do
          expect(policy).not_to be_allowed(:read_issue)
        end

        it 'does not include the admin_issue permission' do
          expect(policy).not_to be_allowed(:admin_issue)
        end

        it 'does not include the update_issue permission' do
          expect(policy).not_to be_allowed(:update_issue)
        end
      end

      context 'with a user that is a project member' do
        let(:policy) { described_class.new(user, issue) }

        before do
          issue.project.team << [user, :reporter]
        end

        it 'includes the read_issue permission' do
          expect(policy).to be_allowed(:read_issue)
        end

        it 'includes the admin_issue permission' do
          expect(policy).to be_allowed(:admin_issue)
        end

        it 'includes the update_issue permission' do
          expect(policy).to be_allowed(:update_issue)
        end
      end

      context 'without a user' do
        let(:policy) { described_class.new(nil, issue) }

        it 'does not include the read_issue permission' do
          expect(policy).not_to be_allowed(:read_issue)
        end

        it 'does not include the admin_issue permission' do
          expect(policy).not_to be_allowed(:admin_issue)
        end

        it 'does not include the update_issue permission' do
          expect(policy).not_to be_allowed(:update_issue)
        end
      end
    end
  end
end
