require 'rails_helper'

RSpec.describe CustomEmoji, type: :model do
  subject { create(:custom_emoji) }

  it { is_expected.to belong_to(:project) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_uniqueness_of(:name).scoped_to(:project_id) }

  describe "#emoji_type" do
    context 'file is an image' do
      # The default for the factory is ofcourse an image
      let(:custom_emoji) { build(:custom_emoji) }

      it 'allow it' do
        expect(custom_emoji.save).to be_truthy
      end
    end

    context 'not an image' do
      let(:custom_emoji) do
        build(:custom_emoji, emoji: fixture_file_upload(Rails.root + "spec/fixtures/doc_sample.txt", "`/txt"))
      end

      it 'returns an error' do
        custom_emoji.save
        expect(custom_emoji.errors[:emoji]).to include "only images allowed"
      end
    end
  end
end
