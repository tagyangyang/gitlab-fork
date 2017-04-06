class CommitStatusPolicy < BasePolicy
  delegate { @subject.project }
end
