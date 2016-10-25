module HasStatus
  extend ActiveSupport::Concern

  AVAILABLE_STATUSES = %w[created pending running
                          success success_with_warnings
                          failed canceled skipped]
  STARTED_STATUSES = %w[running success failed skipped]
  ACTIVE_STATUSES = %w[pending running]
  COMPLETED_STATUSES = %w[success success_with_warnings failed canceled]
  ORDERED_STATUSES = %w[failed pending running canceled
                        success success_with_warnings skipped]

  class_methods do
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
    validates :status, inclusion: { in: AVAILABLE_STATUSES }

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
    STARTED_STATUSES.include?(status) && started_at
  end

  def active?
    ACTIVE_STATUSES.include?(status)
  end

  def complete?
    COMPLETED_STATUSES.include?(status)
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
