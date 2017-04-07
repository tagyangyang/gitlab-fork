require 'spec_helper'

describe MergeRequestEntity do
  let(:project)  { create :empty_project }
  let(:resource) { create(:merge_request, source_project: project, target_project: project) }
  let(:user)     { create(:user) }

  let(:request) { double('request', current_user: user) }

  subject do
    described_class.new(resource, request: request).as_json
  end

  it 'includes author' do
    req = double('request')

    author_payload = UserEntity
      .represent(resource.author, request: req)
      .as_json

    expect(subject[:author]).to eq(author_payload)
  end

  it 'includes pipeline' do
    req = double('request', current_user: user)
    pipeline = build_stubbed(:ci_pipeline)
    allow(resource).to receive(:head_pipeline).and_return(pipeline)

    pipeline_payload = PipelineEntity
      .represent(pipeline, request: req)
      .as_json

    expect(subject[:pipeline]).to eq(pipeline_payload)
  end

  it 'has important MergeRequest attributes' do
    expect(subject).to include(:diff_head_sha, :merge_commit_message,
                              :has_conflicts, :has_ci)
  end

  it 'has cancel_merge_when_pipeline_succeeds_path' do
    project.team << [user, :master]

    expect(subject[:cancel_merge_when_pipeline_succeeds_path]).
      to eq("/#{resource.project.full_path}/merge_requests/#{resource.iid}/cancel_merge_when_pipeline_succeeds")
  end

  it 'has merge_path' do
    project.team << [user, :master]

    expect(subject[:merge_path])
      .to eq("/#{resource.project.full_path}/merge_requests/#{resource.iid}/merge")
  end

  it 'has create_issue_to_resolve_discussions_path' do
    project.team << [user, :master]

    expect(subject[:create_issue_to_resolve_discussions_path])
      .to eq("/#{resource.project.full_path}/issues/new?merge_request_for_resolving_discussions_of=#{resource.iid}")
  end

  it 'has remove_wip_path' do
    project.team << [user, :master]

    expect(subject[:remove_wip_path])
      .to eq("/#{resource.project.full_path}/merge_requests/#{resource.iid}/remove_wip")
  end

  it 'has conflict_resolution_ui_path' do
    expect(subject[:conflict_resolution_ui_path])
      .to eq("/#{resource.project.full_path}/merge_requests/#{resource.iid}/conflicts")
  end

  it 'has email_patches_path' do
    expect(subject[:email_patches_path])
      .to eq("/#{resource.project.full_path}/merge_requests/#{resource.iid}.patch")
  end

  it 'has plain_diff_path' do
    expect(subject[:plain_diff_path])
      .to eq("/#{resource.project.full_path}/merge_requests/#{resource.iid}.diff")
  end

  it 'has target_branch_path' do
    expect(subject[:target_branch_path])
      .to eq("/#{resource.target_project.full_path}/branches/#{resource.target_branch}")
  end

  it 'has source_branch_path' do
    expect(subject[:source_branch_path])
      .to eq("/#{resource.source_project.full_path}/branches/#{resource.source_branch}")
  end

  it 'has merge_commit_message_with_description' do
    expect(subject[:merge_commit_message_with_description])
      .to eq(resource.merge_commit_message(include_description: true))
  end

  describe 'diff_head_commit_short_id' do
    context 'when no diff head commit' do
      let(:project) { create :empty_project }

      it 'returns nil' do
        expect(subject[:diff_head_commit_short_id]).to be_nil
      end
    end

    context 'when diff head commit present' do
      let(:project) { create :project }

      it 'returns diff head commit short id' do
        expect(subject[:diff_head_commit_short_id]).to eq(resource.diff_head_commit.short_id)
      end
    end
  end

  describe 'ci_status' do
    let(:project) { create :project }

    context 'when no head pipeline' do
      it 'return status using CiService' do
        ci_service = double(MockCiService)
        ci_status = double

        allow(resource.source_project)
          .to receive(:ci_service)
          .and_return(ci_service)

        allow(resource).to receive(:head_pipeline).and_return(nil)

        expect(ci_service).to receive(:commit_status)
          .with(resource.diff_head_sha, resource.source_branch)
          .and_return(ci_status)

        expect(subject[:ci_status]).to eq(ci_status)
      end
    end

    context 'when head pipeline present' do
      let(:pipeline) { build_stubbed(:ci_pipeline) }

      before do
        allow(resource).to receive(:head_pipeline).and_return(pipeline)
      end

      context 'success with warnings' do
        before do
          allow(pipeline).to receive(:success?) { true }
          allow(pipeline).to receive(:has_warnings?) { true }
        end

        it 'returns "success_with_warnings"' do
          expect(subject[:ci_status]).to eq('success_with_warnings')
        end
      end

      context 'pipeline HAS status AND its not success with warnings' do
        before do
          allow(pipeline).to receive(:success?) { false }
          allow(pipeline).to receive(:has_warnings?) { false }
        end

        it 'returns pipeline status' do
          expect(subject[:ci_status]).to eq('pending')
        end
      end

      context 'pipeline has NO status AND its not success with warnings' do
        before do
          allow(pipeline).to receive(:status) { nil }
          allow(pipeline).to receive(:success?) { false }
          allow(pipeline).to receive(:has_warnings?) { false }
        end

        it 'returns "preparing"' do
          expect(subject[:ci_status]).to eq('preparing')
        end
      end
    end
  end

  it 'includes merge_event' do
    event = create(:event, :merged, author: user, project: resource.project, target: resource)

    event_payload = EventEntity
      .represent(event)
      .as_json

    expect(subject[:merge_event]).to eq(event_payload)
  end

  it 'includes closed_event' do
    event = create(:event, :closed, author: user, project: resource.project, target: resource)

    event_payload = EventEntity
      .represent(event)
      .as_json

    expect(subject[:closed_event]).to eq(event_payload)
  end

  describe 'diverged_commits_count' do
    context 'when MR open and its diverging' do
      it 'returns diverged commits count' do
        allow(resource).to receive_messages(open?: true, diverged_from_target_branch?: true,
                                            diverged_commits_count: 10)

        expect(subject[:diverged_commits_count]).to eq(10)
      end
    end

    context 'when MR is not open' do
      it 'returns 0' do
        allow(resource).to receive_messages(open?: false)

        expect(subject[:diverged_commits_count]).to be_zero
      end
    end

    context 'when MR is not diverging' do
      it 'returns 0' do
        allow(resource).to receive_messages(open?: true, diverged_from_target_branch?: false)

        expect(subject[:diverged_commits_count]).to be_zero
      end
    end
  end

  context 'issues_links' do
    let(:project) { create(:project, :private, creator: user, namespace: user.namespace) }
    let(:issue_a) { create(:issue, project: project) }
    let(:issue_b) { create(:issue, project: project) }

    let(:resource) do
      create(:merge_request,
             source_project: project, target_project: project,
             description: "Fixes #{issue_a.to_reference} Related #{issue_b.to_reference}")
    end

    before do
      project.team << [user, :developer]

      allow(resource.project).to receive(:default_branch)
        .and_return(resource.target_branch)
    end

    describe 'closing' do
      let(:sentence) { subject[:issues_links][:closing] }

      it 'presents closing issues links' do
        expect(sentence).to match("#{project.full_path}/issues/#{issue_a.iid}")
      end

      it 'does not present related issues links' do
        expect(sentence).not_to match("#{project.full_path}/issues/#{issue_b.iid}")
      end
    end

    describe 'mentioned_but_not_closing' do
      let(:sentence) { subject[:issues_links][:mentioned_but_not_closing] }

      it 'presents related issues links' do
        expect(sentence).to match("#{project.full_path}/issues/#{issue_b.iid}")
      end

      it 'does not present closing issues links' do
        expect(sentence).not_to match("#{project.full_path}/issues/#{issue_a.iid}")
      end
    end
  end
end
