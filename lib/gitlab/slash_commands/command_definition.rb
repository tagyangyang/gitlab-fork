module Gitlab
  module SlashCommands
    class CommandDefinition
      attr_accessor :name, :aliases, :description, :humanized, :params, :condition_block, :action_block

      def initialize(name, attributes = {})
        @name = name

        @aliases         = attributes[:aliases] || []
        @description     = attributes[:description] || ''
        @humanized       = attributes[:humanized] || ''
        @params          = attributes[:params] || []
        @condition_block = attributes[:condition_block]
        @action_block    = attributes[:action_block]
      end

      def all_names
        [name, *aliases]
      end

      def noop?
        action_block.nil?
      end

      def available?(opts)
        return true unless condition_block

        context = OpenStruct.new(opts)
        context.instance_exec(&condition_block)
      end

      def humanize(context, opts, arg)
        return unless available?(opts)

        if humanized.respond_to?(:call)
          execute_block(humanized, context, arg)
        else
          humanized
        end
      end

      def execute(context, opts, arg)
        return if noop? || !available?(opts)
        execute_block(action_block, context, arg)
      end

      def to_h(opts)
        desc = description
        if desc.respond_to?(:call)
          context = OpenStruct.new(opts)
          desc = context.instance_exec(&desc) rescue ''
        end

        {
          name: name,
          aliases: aliases,
          description: desc,
          params: params
        }
      end

      private

      def execute_block(block, context, arg)
        if arg.present?
          context.instance_exec(arg, &block)
        elsif block.arity == 0
          context.instance_exec(&block)
        end
      end
    end
  end
end
