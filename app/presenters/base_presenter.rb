require 'forwardable'

module BasePresenter
  extend Forwardable

  attr_reader :object, :current_user

  def_delegators :@object, :persisted?, :id, :model_name, :to_param

  def initialize(object, current_user = nil)
    @object = object
    @current_user = current_user
  end

  def presenter?
    true
  end
end
