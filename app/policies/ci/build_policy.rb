module Ci
  class BuildPolicy < CommitStatusPolicy
    %w[read create update admin].each do |action|
      rule { ~can?(:"#{action}_build") }.prevent :"#{action}_commit_status"
    end
  end
end
