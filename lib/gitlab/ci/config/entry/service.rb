module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a configuration of Docker service.
        #
        class Service < Node
          include Validatable

          ALLOWED_KEYS = %i[image alias command]

          validations do
            validate do
              unless hash? || string?
                errors.add(:config, 'should be a hash or a string')
              end
            end

            validates :image, type: String, presence: true
            validates :alias, type: String, allow_nil: true
            validates :command, type: String, allow_nil: true
          end

          def hash?
            @config.is_a?(Hash)
          end

          def string?
            @config.is_a?(String)
          end

          def image
            value[:image]
          end

          def alias
            value[:alias]
          end

          def command
            value[:command]
          end

          def value
            case @config
            when String then { image: @config }
            when Hash then @config
            else {}
            end
          end
        end
      end
    end
  end
end
