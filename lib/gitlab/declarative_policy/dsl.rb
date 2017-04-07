module DeclarativePolicy
  class RuleDsl
    def initialize(context_class)
      @context_class = context_class
    end

    def can?(ability)
      Rule::Ability.new(ability)
    end

    def all?(*rules)
      Rule::And.new(rules)
    end

    def any?(*rules)
      Rule::Or.new(rules)
    end

    def none?(*rules)
      ~Rule::Or.new(rules)
    end

    def method_missing(m, *a, &b)
      return super unless a.size == 0 && !block_given?

      Rule::Condition.new(m)
    end
  end

  class PolicyDsl
    def initialize(context_class, rule)
      @context_class = context_class
      @rule = rule
    end

    def policy(&b)
      instance_eval(&b)
    end

    def enable(*abilities)
      @context_class.enable_when(abilities, @rule)
    end

    def prevent(*abilities)
      @context_class.prevent_when(abilities, @rule)
    end

    def prevent_all
      @context_class.prevent_all_when(@rule)
    end

    def method_missing(m, *a, &b)
      return super unless @context_class.respond_to?(m)

      @context_class.__send__(m, *a, &b)
    end
  end
end
