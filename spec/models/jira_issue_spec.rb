require 'spec_helper'

describe JiraIssue do
  let(:project) { create(:project) }
  subject { described_class.new('JIRA-123', project) }

  describe 'id' do
    subject { super().id }
    it { is_expected.to eq('JIRA-123') }
  end

  describe 'iid' do
    subject { super().iid }
    it { is_expected.to eq('JIRA-123') }
  end

  describe 'to_s' do
    subject { super().to_s }
    it { is_expected.to eq('JIRA-123') }
  end

  describe :== do
    specify { expect(subject).to eq(described_class.new('JIRA-123', project)) }
    specify { expect(subject).not_to eq(described_class.new('JIRA-124', project)) }

    it 'only compares with JiraIssues' do
      expect(subject).not_to eq('JIRA-123')
    end
  end
end
