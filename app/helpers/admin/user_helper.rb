# Helper methods for Admin interface User settings
module Admin
  module UserHelper
    def role_type_choices
      [
        ['Regular', :regular],
        ['Admin', :admin],
        ['Auditor', :auditor]
      ]
    end
  end
end
