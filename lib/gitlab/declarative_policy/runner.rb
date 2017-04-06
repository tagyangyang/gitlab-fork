module DeclarativePolicy
  class Runner
    class State
      def initialize
        @enabled = false
        @prevented = false
      end

      def enable!
        @enabled = true
      end

      def enabled?
        @enabled
      end

      def prevent!
        @prevented = true
      end

      def prevented?
        @prevented
      end

      def pass?
        !prevented? && enabled?
      end
    end

    attr_reader :steps
    def initialize(steps)
      @steps = steps.flat_map(&:flattened)
    end

    def cached?
      !!@state
    end

    def score
      return 0 if cached?
      steps.map(&:score).inject(0, :+)
    end

    def merge_runner(other)
      Runner.new(@steps + other.steps)
    end

    def pass?
      run unless cached?

      @state.pass?
    end

    def debug(out=$stderr)
      run(out)
    end

    private

    def run(debug=nil)
      scored = @steps.map { |s| [s.score, s] }.sort_by { |(s, _)| s }
      @steps = scored.map { |(_, s)| s }

      @state = State.new

      scored.each do |original_score, step|
        passed = nil
        case step.action
        when :enable then
          unless @state.enabled? || @state.prevented?
            passed = step.pass?
            @state.enable! if passed
          end

          debug << inspect_step(step, original_score, passed) if debug
        when :prevent then
          unless @state.prevented?
            passed = step.pass?
            @state.prevent! if passed
          end

          debug << inspect_step(step, original_score, passed) if debug
        else raise 'invalid action'
        end
      end

      @state
    end

    def inspect_step(step, original_score, passed)
      symbol =
        case passed
        when true then '+'
        when false then '-'
        when nil then ' '
        end

      "#{symbol} [#{original_score.to_i}] #{step.repr}\n"
    end
  end
end
