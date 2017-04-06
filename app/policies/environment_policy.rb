class EnvironmentPolicy < BasePolicy
  delegate { @subject.project }
end
