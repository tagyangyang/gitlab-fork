import Timeago from 'timeago.js';

export default class MergeRequestStore {

  constructor(data) {
    // TODO: Remove this
    this.rawData = data || {};

    const currentUser = data.current_user;

    this.targetBranch = data.target_branch;
    this.sourceBranch = data.source_branch;
    this.mergeStatus = data.merge_status;
    this.sha = data.diff_head_sha;
    this.commitMessage = data.merge_commit_message;
    this.commitMessageWithDescription = data.merge_commit_message_with_description;
    this.divergedCommitsCount = data.diverged_commits_count;

    this.updatedAt = data.updated_at;
    this.mergedAt = MergeRequestStore.getEventDate(data.merge_event);
    // FIXME: replace it with merge_event.author
    this.mergedBy = MergeRequestStore.getUserObject(data.author);

    // FIXME: replace it with close_event.author
    this.closedBy = MergeRequestStore.getUserObject(data.author);
    this.closedAt = MergeRequestStore.getEventDate(data.closed_event);

    this.sourceBranchPath = data.source_branch_path;
    this.targetBranchPath = data.target_branch_path;
    this.conflictResolutionPath = data.conflict_resolution_ui_path;
    this.removeWIPPath = data.remove_wip_path;
    this.sourceBranchRemoved = !data.source_branch_exists;
    this.mergePath = data.merge_path;
    this.emailPatchesPath = data.email_pathes_path;
    this.plainDiffPath = data.plain_diff_path;

    this.canRemoveSourceBranch = currentUser.can_remove_source_branch || false;
    this.canRevert = currentUser.can_revert || false;
    this.canResolveConflicts = currentUser.can_resolve_conflicts || false;
    this.canMerge = currentUser.can_merge || false;
    this.canUpdateMergeRequest = currentUser.can_update_merge_request || false;
    this.canResolveConflictsInUI = data.conflicts_can_be_resolved_in_ui || false;
    this.canBeCherryPicked = data.can_be_cherry_picked || false;
    this.canBeMerged = data.can_be_merged || false;
    this.isOpen = data.state === 'opened' || false;

    this.setState(data);
  }

  setState(data) {
    if (data.state === 'opened') {
      if (data.project_archived) {
        this.state = 'archived';
      } else if (data.branch_missing) {
        this.state = 'missingBranch';
      } else if (data.has_no_commits) {
        this.state = 'nothingToMerge';
      } else if (data.has_conflicts) {
        this.state = 'conflicts';
      } else if (data.work_in_progress) {
        this.state = 'workInProgress';
      } else if (!this.canMerge) {
        this.state = 'notAllowedToMerge';
      } else if (this.canBeMerged) {
        this.state = 'readyToMerge';
      } else if (this.mergeStatus === 'unchecked') {
        this.state = 'checking';
      }
    } else {
      switch (data.state) {
        case 'merged':
          this.state = 'merged';
          break;
        case 'closed':
          this.state = 'closed';
          break;
        case 'locked':
          this.state = 'locked';
          break;
        default:
          this.state = null;
      }
    }
  }

  static getUserObject(user) {
    return {
      name: user.name || '',
      username: user.username || '',
      webUrl: user.web_url || '',
      avatarUrl: user.avatar_url || '',
    };
  }

  static getEventDate(event) {
    const timeagoInstance = new Timeago();

    if (!event) {
      return '';
    }

    return timeagoInstance.format(event.updated_at);
  }

}
