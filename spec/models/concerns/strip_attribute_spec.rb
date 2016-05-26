require 'spec_helper'

describe Milestone, "StripAttribute" do
  let(:milestone) { create(:milestone) }

  describe ".strip_attributes" do
    it { expect(described_class).to respond_to(:strip_attributes) }
    it { expect(described_class.strip_attrs).to include(:title) }
  end

  describe "#strip_attributes" do
    before do
      milestone.title = '    8.3   '
      milestone.valid?
    end

    it { expect(milestone.title).to eq('8.3') }
  end

end
