require 'spec_helper'

describe Key, models: true do
  include EmailHelpers
  include Gitlab::CurrentSettings

  describe 'modules' do
    subject { described_class }
    it { is_expected.to include_module(Gitlab::CurrentSettings) }
  end

  describe "Associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "Validation" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_length_of(:title).is_at_most(255) }

    it { is_expected.to validate_presence_of(:key) }
    it { is_expected.to validate_length_of(:key).is_at_most(5000) }
    it { is_expected.to allow_value(attributes_for(:ecdsa_key)[:key]).for(:key) }
    it { is_expected.to allow_value(attributes_for(:dsa_key_2048)[:key]).for(:key) }
    it { is_expected.to allow_value(attributes_for(:rsa_key_2048)[:key]).for(:key) }
    it { is_expected.not_to allow_value('foo-bar').for(:key) }
    it { is_expected.not_to allow_value("#{attributes_for(:dsa_key_2048)[:key]}\nfoo").for(:key) }
  end

  describe "Methods" do
    let(:user) { create(:user) }
    it { is_expected.to respond_to :projects }
    it { is_expected.to respond_to :publishable_key }

    describe "#publishable_keys" do
      it 'replaces SSH key comment with simple identifier of username + hostname' do
        expect(build(:key, user: user).publishable_key).to include("#{user.name} (#{Gitlab.config.gitlab.host})")
      end
    end

    describe "#update_last_used_at" do
      let(:key) { create(:key) }

      context 'when key was not updated during the last day' do
        before do
          allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain).
            and_return('000000')
        end

        it 'enqueues a UseKeyWorker job' do
          expect(UseKeyWorker).to receive(:perform_async).with(key.id)
          key.update_last_used_at
        end
      end

      context 'when key was updated during the last day' do
        before do
          allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain).
            and_return(false)
        end

        it 'does not enqueue a UseKeyWorker job' do
          expect(UseKeyWorker).not_to receive(:perform_async)
          key.update_last_used_at
        end
      end
    end
  end

  context "validation of uniqueness (based on fingerprint uniqueness)" do
    let(:user) { create(:user) }

    it "accepts the key once" do
      expect(build(:key, user: user)).to be_valid
    end

    it "does not accept the exact same key twice" do
      create(:key, user: user)
      expect(build(:key, user: user)).not_to be_valid
    end

    it "does not accept a duplicate key with a different comment" do
      create(:key, user: user)
      duplicate = build(:key, user: user)
      duplicate.key << ' extra comment'
      expect(duplicate).not_to be_valid
    end
  end

  context "validate it is a fingerprintable key" do
    it "accepts the fingerprintable key" do
      expect(build(:key)).to be_valid
    end

    it 'rejects an unfingerprintable key that contains a space' do
      key = build(:key)

      # Not always the middle, but close enough
      key.key = key.key[0..100] + ' ' + key.key[101..-1]

      expect(key).not_to be_valid
    end

    it 'rejects the unfingerprintable key (not a key)' do
      expect(build(:key, key: 'ssh-rsa an-invalid-key==')).not_to be_valid
    end

    it 'rejects the multiple line key' do
      key = build(:key)
      key.key.tr!(' ', "\n")
      expect(key).not_to be_valid
    end
  end

  context 'validate it meets minimum bit length' do
    it 'accepts a RSA key of the minimum bit length' do
      expect(build(:key)).to be_valid
    end

    it 'accepts a RSA key above the minimum bit length' do
      expect(build(:another_key)).to be_valid
    end

    it 'rejects a RSA key below minimum bit length' do
      stub_application_setting(minimum_rsa_bits: 4096)

      expect(build(:key)).not_to be_valid
    end

    it 'accepts an ECDSA key above the minimum bit length' do
      expect(build(:ecdsa_key)).to be_valid
    end

    it 'rejects an ECDSA key below minimum bit length' do
      stub_application_setting(minimum_ecdsa_bits: 384)

      expect(build(:ecdsa_key)).not_to be_valid
    end
  end

  context 'validate the key type is allowed' do
    it 'accepts RSA, ECDSA, and DSA keys by default' do
      expect(build(:key)).to be_valid
      expect(build(:ecdsa_key)).to be_valid
      expect(build(:dsa_key_2048)).to be_valid
    end

    it 'rejects RSA and ECDSA key if DSA is the only allowed type' do
      stub_application_setting(allowed_key_types: ['dsa'])

      expect(build(:key)).not_to be_valid
      expect(build(:ecdsa_key)).not_to be_valid
      expect(build(:dsa_key_2048)).to be_valid
    end

    it 'rejects RSA and DSA key if ECDSA is the only allowed type' do
      stub_application_setting(allowed_key_types: ['ecdsa'])

      expect(build(:key)).not_to be_valid
      expect(build(:ecdsa_key)).to be_valid
      expect(build(:dsa_key_2048)).not_to be_valid
    end

    it 'rejects DSA and ECDSA key if RSA is the only allowed type' do
      stub_application_setting(allowed_key_types: ['rsa'])

      expect(build(:key)).to be_valid
      expect(build(:ecdsa_key)).not_to be_valid
      expect(build(:dsa_key_2048)).not_to be_valid
    end
  end

  context 'callbacks' do
    it 'adds new key to authorized_file' do
      key = build(:personal_key, id: 7)
      expect(GitlabShellWorker).to receive(:perform_async).with(:add_key, key.shell_id, key.key)
      key.save!
    end

    it 'removes key from authorized_file' do
      key = create(:personal_key)
      expect(GitlabShellWorker).to receive(:perform_async).with(:remove_key, key.shell_id, key.key)
      key.destroy
    end
  end

  describe '#key=' do
    let(:valid_key) { attributes_for(:key)[:key] }

    it 'strips white spaces' do
      expect(described_class.new(key: " #{valid_key} ").key).to eq(valid_key)
    end
  end

  describe 'notification' do
    let(:user) { create(:user) }

    it 'sends a notification' do
      perform_enqueued_jobs do
        create(:key, user: user)
      end

      should_email(user)
    end
  end
end
