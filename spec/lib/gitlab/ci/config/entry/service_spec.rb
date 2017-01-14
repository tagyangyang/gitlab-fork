require 'spec_helper'

describe Gitlab::Ci::Config::Entry::Service do
  let(:entry) { described_class.new(config) }

  before { entry.compose! }

  context 'when configuration is a string' do
    let(:config) { 'postgresql:9.5' }

    describe '#string?' do
      it 'is string configuration' do
        expect(entry).to be_string
      end
    end

    describe '#hash?' do
      it 'is not hash configuration' do
        expect(entry).not_to be_hash
      end
    end

    describe '#valid?' do
      it 'is valid' do
        expect(entry).to be_valid
      end
    end

    describe '#value' do
      it 'returns valid hash' do
        expect(entry.value).to include(image: 'postgresql:9.5')
      end
    end

    describe '#image' do
      it 'returns service image' do
        expect(entry.image).to eq 'postgresql:9.5'
      end
    end

    describe '#alias' do
      it 'returns service alias' do
        expect(entry.alias).to be_nil
      end
    end

    describe '#command' do
      it 'returns service command' do
        expect(entry.command).to be_nil
      end
    end
  end

  context 'when configuration is a hash' do
    let(:config) do
      { image: 'postgresql:9.5', alias: 'db', command: 'cmd' }
    end

    describe '#string?' do
      it 'is not string configuration' do
        expect(entry).not_to be_string
      end
    end

    describe '#hash?' do
      it 'is hash configuration' do
        expect(entry).to be_hash
      end
    end

    describe '#valid?' do
      it 'is valid' do
        expect(entry).to be_valid
      end
    end

    describe '#value' do
      it 'returns valid hash' do
        expect(entry.value).to eq config
      end
    end

    describe '#image' do
      it 'returns service image' do
        expect(entry.image).to eq 'postgresql:9.5'
      end
    end

    describe '#alias' do
      it 'returns service alias' do
        expect(entry.alias).to eq 'db'
      end
    end

    describe '#command' do
      it 'returns service command' do
        expect(entry.command).to eq 'cmd'
      end
    end
  end
end
