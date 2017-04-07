module DeclarativePolicy
  module Cache
    class << self
      def user_key(user)
        return '<anonymous>' if user.nil?
        id_for(user)
      end

      def subject_key(subject)
        return '<nil>' if subject.nil?
        return subject.inspect if subject.is_a?(Symbol)
        "#{subject.class.name}:#{id_for(subject)}"
      end

      private

      def id_for(obj)
        obj.respond_to?(:id) ? obj.id.to_s : "##{obj.object_id}"
      end
    end
  end
end
