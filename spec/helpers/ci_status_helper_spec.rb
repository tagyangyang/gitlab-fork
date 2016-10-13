require 'spec_helper'

describe CiStatusHelper do
  include IconsHelper

  let(:success_commit) { double("Ci::Pipeline", status: 'success') }
  let(:failed_commit) { double("Ci::Pipeline", status: 'failed') }
  let(:success_with_warnings) { double("Ci::Pipeline", status: 'success_with_warnings') }

  describe 'ci_icon_for_status' do
    it 'renders the correct svg on success' do
      expect(helper).to receive(:render).with('shared/icons/icon_status_success.svg', anything)
      helper.ci_icon_for_status(success_commit.status)
    end

    it 'renders the correct svg on failure' do
      expect(helper).to receive(:render).with('shared/icons/icon_status_failed.svg', anything)
      helper.ci_icon_for_status(failed_commit.status)
    end

    it 'renders the correct svg on success with warnings' do
      expect(helper).to receive(:render).with('shared/icons/icon_status_warning.svg', anything)
      helper.ci_icon_for_status(success_with_warnings.status)
    end
  end

  describe 'ci_label_for_status' do
    it 'returns the correct label on success' do
      expect(helper.ci_label_for_status(success_commit.status)).to eq('passed')
    end

    it 'returns the correct label on failure' do
      expect(helper.ci_label_for_status(failed_commit.status)).to eq('failed')
    end

    it 'returns the correct label on success with warnings' do
      expect(helper.ci_label_for_status(success_with_warnings.status)).to eq('passed with warnings')
    end
  end
end
