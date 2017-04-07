require 'spec_helper'

describe CommitStatus, :models do
  let(:project) { create(:project, :repository) }

  let(:pipeline) do
    create(:ci_pipeline, project: project, sha: project.commit.id)
  end

  let(:commit_status) { create_status }

  def create_status(args = {})
    create(:commit_status, args.merge(pipeline: pipeline))
  end

  it { is_expected.to belong_to(:pipeline) }
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:project) }
  it { is_expected.to belong_to(:auto_canceled_by) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_inclusion_of(:status).in_array(%w(pending running failed success canceled)) }

  it { is_expected.to delegate_method(:sha).to(:pipeline) }
  it { is_expected.to delegate_method(:short_sha).to(:pipeline) }

  it { is_expected.to respond_to :success? }
  it { is_expected.to respond_to :failed? }
  it { is_expected.to respond_to :running? }
  it { is_expected.to respond_to :pending? }

  describe '#author' do
    subject { commit_status.author }
    before { commit_status.author = User.new }

    it { is_expected.to eq(commit_status.user) }
  end

  describe '#started?' do
    subject { commit_status.started? }

    context 'without started_at' do
      before { commit_status.started_at = nil }

      it { is_expected.to be_falsey }
    end

    %w[running success failed].each do |status|
      context "if commit status is #{status}" do
        before { commit_status.status = status }

        it { is_expected.to be_truthy }
      end
    end

    %w[pending canceled].each do |status|
      context "if commit status is #{status}" do
        before { commit_status.status = status }

        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#active?' do
    subject { commit_status.active? }

    %w[pending running].each do |state|
      context "if commit_status.status is #{state}" do
        before { commit_status.status = state }

        it { is_expected.to be_truthy }
      end
    end

    %w[success failed canceled].each do |state|
      context "if commit_status.status is #{state}" do
        before { commit_status.status = state }

        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#complete?' do
    subject { commit_status.complete? }

    %w[success failed canceled].each do |state|
      context "if commit_status.status is #{state}" do
        before { commit_status.status = state }

        it { is_expected.to be_truthy }
      end
    end

    %w[pending running].each do |state|
      context "if commit_status.status is #{state}" do
        before { commit_status.status = state }

        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#auto_canceled?' do
    subject { commit_status.auto_canceled? }

    context 'when it is canceled' do
      before do
        commit_status.update(status: 'canceled')
      end

      context 'when there is auto_canceled_by' do
        before do
          commit_status.update(auto_canceled_by: create(:ci_empty_pipeline))
        end

        it 'is auto canceled' do
          is_expected.to be_truthy
        end
      end

      context 'when there is no auto_canceled_by' do
        it 'is not auto canceled' do
          is_expected.to be_falsey
        end
      end
    end
  end

  describe '#duration' do
    subject { commit_status.duration }

    it { is_expected.to eq(120.0) }

    context 'if the building process has not started yet' do
      before do
        commit_status.started_at = nil
        commit_status.finished_at = nil
      end

      it { is_expected.to be_nil }
    end

    context 'if the building process has started' do
      before do
        commit_status.started_at = Time.now - 1.minute
        commit_status.finished_at = nil
      end

      it { is_expected.to be_a(Float) }
      it { is_expected.to be > 0.0 }
    end
  end

  describe '.latest' do
    subject { described_class.latest.order(:id) }

    let(:statuses) do
      [create_status(name: 'aa', ref: 'bb', status: 'running'),
       create_status(name: 'cc', ref: 'cc', status: 'pending'),
       create_status(name: 'aa', ref: 'cc', status: 'success'),
       create_status(name: 'cc', ref: 'bb', status: 'success'),
       create_status(name: 'aa', ref: 'bb', status: 'success')]
    end

    it 'returns unique statuses' do
      is_expected.to eq(statuses.values_at(3, 4))
    end
  end

  describe '.running_or_pending' do
    subject { described_class.running_or_pending.order(:id) }

    let(:statuses) do
      [create_status(name: 'aa', ref: 'bb', status: 'running'),
       create_status(name: 'cc', ref: 'cc', status: 'pending'),
       create_status(name: 'aa', ref: nil, status: 'success'),
       create_status(name: 'dd', ref: nil, status: 'failed'),
       create_status(name: 'ee', ref: nil, status: 'canceled')]
    end

    it 'returns statuses that are running or pending' do
      is_expected.to eq(statuses.values_at(0, 1))
    end
  end

  describe '.after_stage' do
    subject { described_class.after_stage(0) }

    let(:statuses) do
      [create_status(name: 'aa', stage_idx: 0),
       create_status(name: 'cc', stage_idx: 1),
       create_status(name: 'aa', stage_idx: 2)]
    end

    it 'returns statuses from second and third stage' do
      is_expected.to eq(statuses.values_at(1, 2))
    end
  end

  describe '.exclude_ignored' do
    subject { described_class.exclude_ignored.order(:id) }

    let(:statuses) do
      [create_status(when: 'manual', status: 'skipped'),
       create_status(when: 'manual', status: 'success'),
       create_status(when: 'manual', status: 'failed'),
       create_status(when: 'on_failure', status: 'skipped'),
       create_status(when: 'on_failure', status: 'success'),
       create_status(when: 'on_failure', status: 'failed'),
       create_status(allow_failure: true, status: 'success'),
       create_status(allow_failure: true, status: 'failed'),
       create_status(allow_failure: false, status: 'success'),
       create_status(allow_failure: false, status: 'failed'),
       create_status(allow_failure: true, status: 'manual'),
       create_status(allow_failure: false, status: 'manual')]
    end

    it 'returns statuses without what we want to ignore' do
      is_expected.to eq(statuses.values_at(0, 1, 2, 3, 4, 5, 6, 8, 9, 11))
    end
  end

  describe '.failed_but_allowed' do
    subject { described_class.failed_but_allowed.order(:id) }

    let(:statuses) do
      [create_status(allow_failure: true, status: 'success'),
       create_status(allow_failure: true, status: 'failed'),
       create_status(allow_failure: false, status: 'success'),
       create_status(allow_failure: false, status: 'failed'),
       create_status(allow_failure: true, status: 'canceled'),
       create_status(allow_failure: false, status: 'canceled'),
       create_status(allow_failure: true, status: 'manual'),
       create_status(allow_failure: false, status: 'manual')]
    end

    it 'returns statuses without what we want to ignore' do
      is_expected.to eq(statuses.values_at(1, 4))
    end
  end

  describe '#before_sha' do
    subject { commit_status.before_sha }

    context 'when no before_sha is set for pipeline' do
      before { pipeline.before_sha = nil }

      it 'returns blank sha' do
        is_expected.to eq(Gitlab::Git::BLANK_SHA)
      end
    end

    context 'for before_sha set for pipeline' do
      let(:value) { '1234' }
      before { pipeline.before_sha = value }

      it 'returns the set value' do
        is_expected.to eq(value)
      end
    end
  end

  describe '#commit' do
    it 'returns commit pipeline has been created for' do
      expect(commit_status.commit).to eq project.commit
    end
  end

  describe '#group_name' do
    subject { commit_status.group_name }

    tests = {
      'rspec:windows' => 'rspec:windows',
      'rspec:windows 0' => 'rspec:windows 0',
      'rspec:windows 0 test' => 'rspec:windows 0 test',
      'rspec:windows 0 1' => 'rspec:windows',
      'rspec:windows 0 1 name' => 'rspec:windows name',
      'rspec:windows 0/1' => 'rspec:windows',
      'rspec:windows 0/1 name' => 'rspec:windows name',
      'rspec:windows 0:1' => 'rspec:windows',
      'rspec:windows 0:1 name' => 'rspec:windows name',
      'rspec:windows 10000 20000' => 'rspec:windows',
      'rspec:windows 0 : / 1' => 'rspec:windows',
      'rspec:windows 0 : / 1 name' => 'rspec:windows name',
      '0 1 name ruby' => 'name ruby',
      '0 :/ 1 name ruby' => 'name ruby'
    }

    tests.each do |name, group_name|
      it "'#{name}' puts in '#{group_name}'" do
        commit_status.name = name

        is_expected.to eq(group_name)
      end
    end
  end

  describe '#detailed_status' do
    let(:user) { create(:user) }

    it 'returns a detailed status' do
      expect(commit_status.detailed_status(user))
        .to be_a Gitlab::Ci::Status::Success
    end
  end

  describe '#sortable_name' do
    tests = {
      'karma' => ['karma'],
      'karma 0 20' => ['karma ', 0, ' ', 20],
      'karma 10 20' => ['karma ', 10, ' ', 20],
      'karma 50:100' => ['karma ', 50, ':', 100],
      'karma 1.10' => ['karma ', 1, '.', 10],
      'karma 1.5.1' => ['karma ', 1, '.', 5, '.', 1],
      'karma 1 a' => ['karma ', 1, ' a']
    }

    tests.each do |name, sortable_name|
      it "'#{name}' sorts as '#{sortable_name}'" do
        commit_status.name = name
        expect(commit_status.sortable_name).to eq(sortable_name)
      end
    end
  end

  describe '#locking_enabled?' do
    before do
      commit_status.lock_version = 100
    end

    subject { commit_status.locking_enabled? }

    context "when changing status" do
      before do
        commit_status.status = "running"
      end

      it "lock" do
        is_expected.to be true
      end

      it "raise exception when trying to update" do
        expect{ commit_status.save }.to raise_error(ActiveRecord::StaleObjectError)
      end
    end

    context "when changing description" do
      before do
        commit_status.description = "test"
      end

      it "do not lock" do
        is_expected.to be false
      end

      it "save correctly" do
        expect(commit_status.save).to be true
      end
    end
  end
end
