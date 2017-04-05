require 'spec_helper'

describe Gitlab::Ci::Trace do
  let(:build) { create(:ci_build) }
  let(:trace) { described_class.new(build) }

  describe '#append' do
    subject { trace.html }

    context 'when build.trace hides runners token' do
      let(:token) { 'my_secret_token' }

      before do
        build.project.update(runners_token: token)
        trace.append(token, 0)
      end

      it { is_expected.not_to include(token) }
    end

    context 'when build.trace hides build token' do
      let(:token) { 'my_secret_token' }

      before do
        build.update(token: token)
        trace.append(token, 0)
      end

      it { is_expected.not_to include(token) }
    end
  end

  describe '#extract_coverage' do
    subject { trace.extract_coverage(regex) }

    before do
      trace.set(data)
    end

    context 'valid content & regex' do
      let(:data) { 'Coverage 1033 / 1051 LOC (98.29%) covered' }
      let(:regex) { '\(\d+.\d+\%\) covered' }

      it { is_expected.to eq(98.29) }
    end

    context 'valid content & bad regex' do
      let(:data) { 'Coverage 1033 / 1051 LOC (98.29%) covered\n' }
      let(:regex) { 'very covered' }

      it { is_expected.to be_nil }
    end

    context 'no coverage content & regex' do
      let(:data) { 'No coverage for today :sad:' }
      let(:regex) { '\(\d+.\d+\%\) covered' }

      it { is_expected.to be_nil }
    end

    context 'multiple results in content & regex' do
      let(:data) { ' (98.39%) covered. (98.29%) covered' }
      let(:regex) { '\(\d+.\d+\%\) covered' }

      it { is_expected.to eq(98.29) }
    end

    context 'using a regex capture' do
      let(:data) { 'TOTAL      9926   3489    65%' }
      let(:regex) { 'TOTAL\s+\d+\s+\d+\s+(\d{1,3}\%)' }

      it { is_expected.to eq(65) }
    end
  end

  describe '#has_trace_file?' do
    context 'when there is no trace' do
      it { expect(build.has_trace_file?).to be_falsey }
      it { expect(build.trace.raw).to be_nil }
    end

    context 'when there is a trace' do
      context 'when trace is stored in file' do
        let(:build_with_trace) { create(:ci_build, :trace) }

        it { expect(build_with_trace.has_trace_file?).to be_truthy }
        it { expect(build_with_trace.trace.raw).to eq('BUILD TRACE') }
      end

      context 'when trace is stored in old file' do
        before do
          allow(build.project).to receive(:ci_id).and_return(999)
          allow(File).to receive(:exist?).with(build.path_to_trace).and_return(false)
          allow(File).to receive(:exist?).with(build.old_path_to_trace).and_return(true)
          allow(File).to receive(:read).with(build.old_path_to_trace).and_return(test_trace)
        end

        it { expect(build.has_trace_file?).to be_truthy }
        it { expect(build.trace.raw).to eq(test_trace) }
      end

      context 'when trace is stored in DB' do
        before do
          allow(build.project).to receive(:ci_id).and_return(nil)
          allow(build).to receive(:read_attribute).with(:trace).and_return(test_trace)
          allow(File).to receive(:exist?).with(build.path_to_trace).and_return(false)
          allow(File).to receive(:exist?).with(build.old_path_to_trace).and_return(false)
        end

        it { expect(build.has_trace_file?).to be_falsey }
        it { expect(build.trace.raw).to eq(test_trace) }
      end
    end
  end

  describe '#trace_file_path' do
    context 'when trace is stored in file' do
      before do
        allow(build).to receive(:has_trace_file?).and_return(true)
        allow(build).to receive(:has_old_trace_file?).and_return(false)
      end

      it { expect(build.trace_file_path).to eq(build.path_to_trace) }
    end

    context 'when trace is stored in old file' do
      before do
        allow(build).to receive(:has_trace_file?).and_return(true)
        allow(build).to receive(:has_old_trace_file?).and_return(true)
      end

      it { expect(build.trace_file_path).to eq(build.old_path_to_trace) }
    end
  end
end
