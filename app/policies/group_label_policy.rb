class GroupLabelPolicy < BasePolicy
  delegate { @subject.project }
end
