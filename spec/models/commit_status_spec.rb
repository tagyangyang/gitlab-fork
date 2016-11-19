require 'spec_helper'

describe CommitStatus, models: true do
  let(:project) { create(:project) }

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
    subject { CommitStatus.latest.order(:id) }

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
    subject { CommitStatus.running_or_pending.order(:id) }

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

  describe '.exclude_ignored' do
    subject { CommitStatus.exclude_ignored.order(:id) }

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
       create_status(allow_failure: false, status: 'failed')]
    end

    it 'returns statuses without what we want to ignore' do
      is_expected.to eq(statuses.values_at(1, 2, 4, 5, 6, 8, 9))
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

  describe '#stages' do
    before do
      create :commit_status, pipeline: pipeline, stage: 'build', name: 'linux', stage_idx: 0, status: 'success'
      create :commit_status, pipeline: pipeline, stage: 'build', name: 'mac', stage_idx: 0, status: 'failed'
      create :commit_status, pipeline: pipeline, stage: 'deploy', name: 'staging', stage_idx: 2, status: 'running'
      create :commit_status, pipeline: pipeline, stage: 'test', name: 'rspec', stage_idx: 1, status: 'success'
    end

    context 'stages list' do
      subject { CommitStatus.where(pipeline: pipeline).stages }

      it 'returns ordered list of stages' do
        is_expected.to eq(%w[build test deploy])
      end
    end

    context 'stages with statuses' do
      subject { CommitStatus.where(pipeline: pipeline).latest.stages_status }

      it 'returns list of stages with statuses' do
        is_expected.to eq({
          'build' => 'failed',
          'test' => 'success',
          'deploy' => 'running'
        })
      end

      context 'when build is retried' do
        before do
          create :commit_status, pipeline: pipeline, stage: 'build', name: 'mac', stage_idx: 0, status: 'success'
        end

        it 'ignores a previous state' do
          is_expected.to eq({
            'build' => 'success',
            'test' => 'success',
            'deploy' => 'running'
          })
        end
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

  describe '.status' do
    subject { CommitStatus.status }

    shared_examples 'build status summary' do
      context 'all successful' do
        let!(:statuses) { Array.new(2) { create(type, status: :success) } }
        it { is_expected.to eq 'success' }
      end

      context 'at least one failed' do
        let!(:statuses) do
          [create(type, status: :success), create(type, status: :failed)]
        end

        it { is_expected.to eq 'failed' }
      end

      context 'at least one running' do
        let!(:statuses) do
          [create(type, status: :success), create(type, status: :running)]
        end

        it { is_expected.to eq 'running' }
      end

      context 'at least one pending' do
        let!(:statuses) do
          [create(type, status: :success), create(type, status: :pending)]
        end

        it { is_expected.to eq 'running' }
      end

      context 'success and failed but allowed to fail' do
        let!(:statuses) do
          [create(type, status: :success),
           create(type, status: :failed, allow_failure: true)]
        end

        it { is_expected.to eq 'success_with_warnings' }
      end

      context 'one failed but allowed to fail' do
        let!(:statuses) do
          [create(type, status: :failed, allow_failure: true)]
        end

        it { is_expected.to eq 'success_with_warnings' }
      end

      context 'one canceled but allowed to fail' do
        let!(:statuses) do
          [create(type, status: :success),
           create(type, status: :canceled, allow_failure: true)]
        end

        it { is_expected.to eq 'success_with_warnings' }
      end

      context 'one success with allowed to fail' do
        let!(:statuses) do
          [create(type, status: :success),
           create(type, status: :success, allow_failure: true)]
        end

        it { is_expected.to eq 'success' }
      end

      context 'success and canceled' do
        let!(:statuses) do
          [create(type, status: :success), create(type, status: :canceled)]
        end

        it { is_expected.to eq 'canceled' }
      end

      context 'one failed and one canceled' do
        let!(:statuses) do
          [create(type, status: :failed), create(type, status: :canceled)]
        end

        it { is_expected.to eq 'failed' }
      end

      context 'one failed but allowed to fail and one canceled' do
        let!(:statuses) do
          [create(type, status: :failed, allow_failure: true),
           create(type, status: :canceled)]
        end

        it { is_expected.to eq 'canceled' }
      end

      context 'one running one canceled' do
        let!(:statuses) do
          [create(type, status: :running), create(type, status: :canceled)]
        end

        it { is_expected.to eq 'running' }
      end

      context 'all canceled' do
        let!(:statuses) do
          [create(type, status: :canceled), create(type, status: :canceled)]
        end

        it { is_expected.to eq 'canceled' }
      end

      context 'one finished and second running but allowed to fail' do
        let!(:statuses) do
          [create(type, status: :success),
           create(type, status: :running, allow_failure: true)]
        end

        it { is_expected.to eq 'running' }
      end
    end

    context 'ci build statuses' do
      let(:type) { :ci_build }

      it_behaves_like 'build status summary'
    end

    context 'generic commit statuses' do
      let(:type) { :generic_commit_status }

      it_behaves_like 'build status summary'
    end
  end
end
