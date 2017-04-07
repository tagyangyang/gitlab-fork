require 'spec_helper'

describe Gitlab::Ci::CronParser do
  shared_examples_for "returns time in the future" do
    it { is_expected.to be > Time.now }
  end

  describe '#next_time_from' do
    subject { described_class.new(cron, cron_timezone).next_time_from(Time.now) }

    context 'when cron and cron_timezone are valid' do
      context 'when specific time' do
        let(:cron) { '3 4 5 6 *' }
        let(:cron_timezone) { 'UTC' }

        it_behaves_like "returns time in the future"

        it 'returns exact time' do
          expect(subject.min).to eq(3)
          expect(subject.hour).to eq(4)
          expect(subject.day).to eq(5)
          expect(subject.month).to eq(6)
        end
      end

      context 'when specific day of week' do
        let(:cron) { '* * * * 0' }
        let(:cron_timezone) { 'UTC' }

        it_behaves_like "returns time in the future"

        it 'returns exact day of week' do
          expect(subject.wday).to eq(0)
        end
      end

      context 'when slash used' do
        let(:cron) { '*/10 */6 */10 */10 *' }
        let(:cron_timezone) { 'UTC' }

        it_behaves_like "returns time in the future"

        it 'returns specific time' do
          expect(subject.min).to be_in([0, 10, 20, 30, 40, 50])
          expect(subject.hour).to be_in([0, 6, 12, 18])
          expect(subject.day).to be_in([1, 11, 21, 31])
          expect(subject.month).to be_in([1, 11])
        end
      end

      context 'when range used' do
        let(:cron) { '0,20,40 * 1-5 * *' }
        let(:cron_timezone) { 'UTC' }

        it_behaves_like "returns time in the future"

        it 'returns specific time' do
          expect(subject.min).to be_in([0, 20, 40])
          expect(subject.day).to be_in((1..5).to_a)
        end
      end

      context 'when cron_timezone is US/Pacific' do
        let(:cron) { '0 0 * * *' }
        let(:cron_timezone) { 'US/Pacific' }

        it_behaves_like "returns time in the future"

        it 'converts time in server time zone' do
          expect(subject.hour).to eq((Time.zone.now.in_time_zone(cron_timezone).utc_offset / 60 / 60).abs)
        end
      end
    end

    context 'when cron and cron_timezone are invalid' do
      let(:cron) { 'invalid_cron' }
      let(:cron_timezone) { 'invalid_cron_timezone' }

      it 'returns nil' do
        is_expected.to be_nil
      end 
    end
  end

  describe '#cron_valid?' do
    subject { described_class.new(cron, Gitlab::Ci::CronParser::VALID_SYNTAX_SAMPLE_TIME_ZONE).cron_valid? }

    context 'when cron is valid' do
      let(:cron) { '* * * * *' }

      it { is_expected.to eq(true) }
    end

    context 'when cron is invalid' do
      let(:cron) { '*********' }

      it { is_expected.to eq(false) }
    end
  end

  describe '#cron_timezone_valid?' do
    subject { described_class.new(Gitlab::Ci::CronParser::VALID_SYNTAX_SAMPLE_CRON, cron_timezone).cron_timezone_valid? }

    context 'when cron is valid' do
      let(:cron_timezone) { 'Europe/Istanbul' }

      it { is_expected.to eq(true) }
    end

    context 'when cron is invalid' do
      let(:cron_timezone) { 'Invalid-zone' }

      it { is_expected.to eq(false) }
    end
  end
end
