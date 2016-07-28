require 'spec_helper'

describe Gitlab::SSHPublicKey, lib: true do
  let(:public_key) { described_class.new(key) }
  let(:key) { 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDPizF8D6ywvnsLKmGH8LjUku9L5YGbnM3RkSQgNxzem6YBCYQ7HHSipqGTYSFBGnNzHm7Ndj0BrMH8ZTwn+X0F3Q+6gUQe/v37OMHhBOazdxU3RDZzrlQs8qqkQr9mqJJcvuCdDI03hoVFEkZg6TzwIv0Sk7dBP4FOG3j83oZ8rQ== dummy@gitlab.com' }

  describe 'unknown key type' do
    it 'determines the key type' do
      ssh_key = described_class.new('foo')

      expect { ssh_key.type }.to raise Gitlab::SSHPublicKey::UnsupportedSSHPublicKeyTypeError
    end
  end

  describe '#type' do
    it 'determines the key type' do
      expect(public_key.type).to eq(:rsa)
    end
  end

  describe '#size' do
    it 'determines the key length in bits' do
      expect(public_key.size).to eq(1024)
    end
  end

  describe '#valid?' do
    context 'with a valid SSH key' do
      it 'returns true' do
        expect(public_key.valid?).to eq(true)
      end
    end

    context 'with an invalid SSH key' do
      let(:key) { 'this is not a key' }

      it 'returns false' do
        expect(public_key.valid?).to eq(false)
      end
    end
  end

  describe '#fingerprint' do
    let(:key) { 'ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt4596k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0=' }
    let(:fingerprint) { '3f:a2:ee:de:b5:de:53:c3:aa:2f:9c:45:24:4c:47:7b' }

    it "generates the key's fingerprint" do
      expect(public_key.fingerprint).to eq(fingerprint)
    end
  end
end
