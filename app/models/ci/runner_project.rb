module Ci
  class RunnerProject < ActiveRecord::Base
    extend Ci::Model
    
    belongs_to :runner
    belongs_to :project

    validates_uniqueness_of :runner_id, scope: :project_id
  end
end
