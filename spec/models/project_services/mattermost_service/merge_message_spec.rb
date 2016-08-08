require 'spec_helper'

describe MattermostService::MergeMessage, models: true do
  subject { MattermostService::MergeMessage.new(params) }

  let(:params) do
    {
      user: {
          name: 'Test User',
          username: 'Test User'
      },
      project: {
        path_with_namespace: 'root/test-project',
        web_url: 'http://localhost:3000/root/empty'
      },
      object_attributes: {
        title: "Issue title\nSecond line",
        id: 10,
        iid: 100,
        assignee_id: 1,
        url: 'url',
        state: 'opened',
        description: 'issue description',
        source_branch: 'source_branch',
        target_branch: 'target_branch',
      }
    }
  end

  context 'opening a MR' do
    it 'returns a message regarding opening of issues' do
      message = subject.message

      expect(message).to start_with '**Test User opened ['
      expect(message).to match /View on GitLab/
    end
  end

  context 'merging a MR' do
    before do
      params[:object_attributes][:state] = 'closed'
    end

    it 'returns a message regarding closing of issues' do
      expect(subject.message).to start_with "**Test User closed ["
    end
  end
end
