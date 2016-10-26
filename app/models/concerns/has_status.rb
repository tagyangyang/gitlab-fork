module HasStatus
  extend ActiveSupport::Concern

  class_methods do
    def available_statuses
      %w[created pending running success failed canceled skipped]
    end

    def started_statuses
      %w[running success failed skipped]
    end

    def active_statuses
      %w[pending running]
    end

    def completed_statuses
      %w[success failed canceled]
    end

    def status
      all.pluck(status_sql).first
    end

    def started_at
      all.minimum(:started_at)
    end

    def finished_at
      all.maximum(:finished_at)
    end

    def all_state_names
      state_machines.values.flat_map(&:states).flat_map { |s| s.map(&:name) }
    end
  end

  included do
    validates :status, inclusion: { in: available_statuses }

    state_machine :status, initial: :created do
      state :created, value: 'created'
      state :pending, value: 'pending'
      state :running, value: 'running'
      state :failed, value: 'failed'
      state :success, value: 'success'
      state :canceled, value: 'canceled'
      state :skipped, value: 'skipped'
    end

    scope :created, -> { where(status: 'created') }
    scope :relevant, -> { where.not(status: 'created') }
    scope :running, -> { where(status: 'running') }
    scope :pending, -> { where(status: 'pending') }
    scope :success, -> { where(status: 'success') }
    scope :failed, -> { where(status: 'failed')  }
    scope :canceled, -> { where(status: 'canceled') }
    scope :skipped, -> { where(status: 'skipped') }
    scope :running_or_pending, -> { where(status: [:running, :pending]) }
    scope :finished, -> { where(status: [:success, :failed, :canceled]) }
  end

  def started?
    self.class.started_statuses.include?(status) && started_at
  end

  def active?
    self.class.active_statuses.include?(status)
  end

  def complete?
    self.class.completed_statuses.include?(status)
  end

  private

  def calculate_duration
    if started_at && finished_at
      finished_at - started_at
    elsif started_at
      Time.now - started_at
    end
  end
end
