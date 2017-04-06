require 'gitlab/declarative_policy'

class BasePolicy < DeclarativePolicy::Base
  desc "User is an instance admin"
  condition(:admin, scope: :user) { @user&.admin? }
  condition(:external_user, scope: :user) { anonymous? || @user.external? }
end
