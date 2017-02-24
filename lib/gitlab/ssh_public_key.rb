require 'net/ssh'

module Gitlab
  class SSHPublicKey
    include Gitlab::Popen

    TYPES = %w[rsa dsa ecdsa].freeze

    Technology = Struct.new(:name, :allowed_sizes)

    Technologies = [
      Technology.new('rsa',   [1024, 2048, 3072, 4096]),
      Technology.new('dsa',   [1024, 2048, 3072]),
      Technology.new('ecdsa', [256, 384, 521])
    ].freeze

    def self.technology_names
      Technologies.map(&:name)
    end

    def self.technology(name)
      Technologies.find { |ssh_key_technology| ssh_key_technology.name == name }
    end
    private_class_method :technology

    def self.allowed_sizes(name)
      technology(name).allowed_sizes
    end

    def self.allowed_type?(type)
      technology_names.include?(type.to_s)
    end

    def initialize(key_text)
      @key_text = key_text
    end

    def valid?
      type.present?
    end

    def type
      return @type if defined?(@type)

      @type =
        case key
        when OpenSSL::PKey::EC
          :ecdsa
        when OpenSSL::PKey::RSA
          :rsa
        when OpenSSL::PKey::DSA
          :dsa
        end
    end

    def size
      return @size if defined?(@size)

      @size =
        case type
        when :ecdsa
          key.public_key.to_bn.num_bits / 2
        when :rsa
          key.n.num_bits
        when :dsa
          key.p.num_bits
        end
    end

    def fingerprint
      @fingerprint ||= key&.fingerprint
    end

    private

    attr_accessor :key_text

    def key
      return @key if defined?(@key)

      @key = begin
        Net::SSH::KeyFactory.load_data_public_key(key_text)
      rescue StandardError, NotImplementedError
        nil
      end
    end
  end
end
