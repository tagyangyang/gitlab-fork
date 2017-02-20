require 'spec_helper'

describe Gitlab::SSHPublicKey, lib: true do
  let(:key) { attributes_for(:key)[:key] }
  let(:public_key) { described_class.new(key) }

  describe '.allowed_type?' do
    it 'determines the key type' do
      expect(described_class.allowed_type?('foo')).to be(false)
    end
  end

  describe '#valid?' do
    context 'with a valid SSH key' do
      it 'returns true' do
        expect(public_key).to be_valid
      end
    end

    context 'with an invalid SSH key' do
      let(:key) { 'this is not a key' }

      it 'returns false' do
        expect(public_key).not_to be_valid
      end
    end
  end

  describe '#type' do
    context 'with a DSA key' do
      let(:key) { attributes_for(:dsa_key)[:key] }

      it 'determines the key type' do
        expect(public_key.type).to eq(:dsa)
      end
    end

    context 'with a ECDSA key' do
      let(:key) { attributes_for(:ecdsa_key)[:key] }

      it 'determines the key type' do
        expect(public_key.type).to eq(:ecdsa)
      end
    end

    context 'with a RSA key' do
      it 'determines the key type' do
        expect(public_key.type).to eq(:rsa)
      end
    end

    context 'with an invalid SSH key' do
      let(:key) { 'this is not a key' }

      it 'determines the key type' do
        expect(public_key.type).to be_nil
      end
    end
  end

  describe '#size' do
    it 'determines the key length in bits' do
      expect(public_key.size).to eq(1024)
    end

    context 'with an invalid SSH key' do
      let(:key) { 'this is not a key' }

      it 'determines the key type' do
        expect(public_key.size).to be_nil
      end
    end
  end

  describe '#fingerprint' do
    let(:fingerprint) { '3f:a2:ee:de:b5:de:53:c3:aa:2f:9c:45:24:4c:47:7b' }

    it "generates the key's fingerprint" do
      expect(public_key.fingerprint).to eq(fingerprint)
    end
  end
end
