mod = Module.new do
  NESTING = ::Rails.env.test? ? 1 : 0

  [:perform_async, :perform_at, :perform_in].each do |name|
    define_method(name) do |*args|
      if ActiveRecord::Base.connection.open_transactions > NESTING
        raise "#{self}.#{name} can not be called in a transaction as this can lead to race conditions"
      end

      super(*args)
    end
  end
end

Sidekiq::Worker::ClassMethods.prepend(mod)
