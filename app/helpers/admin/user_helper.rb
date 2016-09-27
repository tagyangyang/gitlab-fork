# Helper methods for Admin interface User settings
module Admin
  module UserHelper
    def role_type_choices
      User.role_types.keys.collect{|k| [k.titleize, k]}
    end
  end
end
