require 'spec_helper'

describe Gitlab::Ci::Trace::Stream do
  describe '#raw' do
    context 'limit max lines' do
      let(:path) { __FILE__ }
      let(:lines) { File.readlines(path) }

      before do
        allow(described_class).to receive(:LIMIT_SIZE).and_return(random_buffer)
      end

      subject do
        described_class.new do
          File.open(path)
        end
      end

      it 'returns last few lines' do
        10.times do
          last_lines = random_lines

          expected = lines.last(last_lines).join
          result = subject.raw(last_lines: last_lines)

          expect(result).to eq(expected)
          expect(result.encoding).to eq(Encoding.default_external)
        end
      end

      it 'returns everything if trying to get too many lines' do
        result = subject.raw(last_lines: lines.size * 2)

        expect(result).to eq(lines.join)
        expect(result.encoding).to eq(Encoding.default_external)
      end

      it 'returns all contents if last_lines is not specified' do
        result = subject.raw

        expect(result).to eq(lines.join)
        expect(result.encoding).to eq(Encoding.default_external)
      end

      it 'raises an error if not passing an integer for last_lines' do
        expect do
          subject.raw(last_lines: lines)
        end.to raise_error(ArgumentError)
      end

      def random_lines
        Random.rand(lines.size) + 1
      end

      def random_buffer
        Random.rand(subject.size) + 1
      end
    end
  end
end
