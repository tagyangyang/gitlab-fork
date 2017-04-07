import deviseState from '~/vue_merge_request_widget/stores/devise_state';

describe('deviseState', () => {
  it('should return proper state name', () => {
    const context = {
      mergeStatus: 'checked',
      mergeWhenPipelineSucceeds: false,
      canMerge: true,
      onlyAllowMergeIfPipelineSucceeds: false,
      isPipelineFailed: false,
      hasMergeableDiscussionsState: false,
      isPipelineBlocked: false,
      canBeMerged: false,
    };
    const data = {
      project_archived: false,
      branch_missing: false,
      has_no_commits: false,
      has_conflicts: false,
      work_in_progress: false,
    };
    const bound = deviseState.bind(context, data);
    expect(bound()).toEqual(null);

    context.canBeMerged = true;
    expect(bound()).toEqual('readyToMerge');

    context.isPipelineBlocked = true;
    expect(bound()).toEqual('pipelineBlocked');

    context.hasMergeableDiscussionsState = true;
    expect(bound()).toEqual('unresolvedDiscussions');

    context.onlyAllowMergeIfPipelineSucceeds = true;
    context.isPipelineFailed = true;
    expect(bound()).toEqual('pipelineFailed');

    context.canMerge = false;
    expect(bound()).toEqual('notAllowedToMerge');

    context.mergeWhenPipelineSucceeds = true;
    expect(bound()).toEqual('mergeWhenPipelineSucceeds');

    data.work_in_progress = true;
    expect(bound()).toEqual('workInProgress');

    data.has_conflicts = true;
    expect(bound()).toEqual('conflicts');

    context.mergeStatus = 'unchecked';
    expect(bound()).toEqual('checking');

    data.has_no_commits = true;
    expect(bound()).toEqual('nothingToMerge');

    data.branch_missing = true;
    expect(bound()).toEqual('missingBranch');

    data.project_archived = true;
    expect(bound()).toEqual('archived');
  });
});
