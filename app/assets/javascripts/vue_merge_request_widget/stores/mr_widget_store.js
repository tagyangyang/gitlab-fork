import Timeago from 'timeago.js';
import eventHub from '../event_hub';
import { getStateKey } from '../dependencies';

export default class MergeRequestStore {

  constructor(data) {
    this.setData(data);
  }

  setData(data) {
    // TODO: Remove this
    this.rawData = data || {};

    const currentUser = data.current_user;

    this.title = data.title;
    this.targetBranch = data.target_branch;
    this.sourceBranch = data.source_branch;
    this.mergeStatus = data.merge_status;
    this.sha = data.diff_head_sha;
    this.commitMessage = data.merge_commit_message;
    this.commitMessageWithDescription = data.merge_commit_message_with_description;
    this.divergedCommitsCount = data.diverged_commits_count;
    this.pipeline = data.pipeline || {};
    this.deployments = this.deployments || data.deployments || [];

    if (data.issues_links) {
      if (data.issues_links.closing || data.issues_links.mentioned_but_not_closing) {
        const { closing, mentioned_but_not_closing } = data.issues_links;

        this.relatedLinks = {
          closing,
          mentioned: mentioned_but_not_closing,
        };
      }
    }

    this.updatedAt = data.updated_at;
    this.mergedAt = MergeRequestStore.getEventDate(data.merge_event);
    this.closedAt = MergeRequestStore.getEventDate(data.closed_event);
    this.mergedBy = MergeRequestStore.getAuthorObject(data.merge_event);
    this.closedBy = MergeRequestStore.getAuthorObject(data.closed_event);
    this.setToMWPSBy = MergeRequestStore.getAuthorObject({ author: data.merge_user || {} });
    this.mergeUserId = data.merge_user_id;
    this.currentUserId = gon.current_user_id;

    this.sourceBranchPath = data.source_branch_path;
    this.targetBranchPath = data.target_branch_path;
    this.conflictResolutionPath = data.conflict_resolution_ui_path;
    this.cancelAutoMergePath = data.cancel_merge_when_pipeline_succeeds_path;
    this.removeWIPPath = data.remove_wip_path;
    this.sourceBranchRemoved = !data.source_branch_exists;
    this.shouldRemoveSourceBranch = (data.merge_params || {}).should_remove_source_branch || false;
    this.onlyAllowMergeIfPipelineSucceeds = data.only_allow_merge_if_pipeline_succeeds || false;
    this.mergeWhenPipelineSucceeds = data.merge_when_pipeline_succeeds || false;
    this.mergePath = data.merge_path;
    this.statusPath = data.status_path;
    this.emailPatchesPath = data.email_patches_path;
    this.plainDiffPath = data.plain_diff_path;
    this.createIssueToResolveDiscussionsPath = data.create_issue_to_resolve_discussions_path;
    this.ciEnvironmentsStatusPath = data.ci_environments_status_url;
    this.ciStatusPath = data.ci_status_path;
    this.mergeCheckPath = data.merge_check_path;
    this.pipelineStatusPath = data.pipeline_status_path;
    this.mergeActionsContentPath = data.commit_change_content_path;
    this.isRemovingSourceBranch = this.isRemovingSourceBranch || false;

    this.canRemoveSourceBranch = currentUser.can_remove_source_branch || false;
    this.canResolveConflicts = currentUser.can_resolve_conflicts || false;
    this.canMerge = !!data.merge_path;
    this.canCreateIssue = currentUser.can_create_issue || false;
    this.canCancelAutomaticMerge = !!data.cancel_merge_when_pipeline_succeeds_path;
    this.canResolveConflictsInUI = data.conflicts_can_be_resolved_in_ui || false;
    this.canBeMerged = data.can_be_merged || false;

    // Cherry-pick and Revert actions related
    this.canCherryPickInCurrentMR = currentUser.can_cherry_pick_on_current_merge_request || false;
    this.canRevertInCurrentMR = currentUser.can_revert_on_current_merge_request || false;
    this.cherryPickInForkPath = currentUser.cherry_pick_in_fork_path;
    this.revertInForkPath = currentUser.revert_in_fork_path;

    this.isPipelineActive = data.pipeline ? data.pipeline.active : false;
    this.isPipelineFailed = data.pipeline ? (data.pipeline.details.status.group === 'failed' || data.pipeline.details.status.group === 'canceled') : false;
    this.isPipelineBlocked = data.pipeline ? data.pipeline.details.status.group === 'manual' : false;
    this.isOpen = data.state === 'opened' || data.state === 'reopened' || false;
    this.hasMergeableDiscussionsState = data.mergeable_discussions_state === false;
    this.hasCI = data.has_ci;
    this.ciStatus = data.ci_status;

    this.setState(data);
  }

  setState(data) {
    if (this.isOpen) {
      this.state = getStateKey.call(this, data);
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

  updatePipelineData(data) {
    const newStatus = data.status;

    if (newStatus) {
      if (newStatus !== this.pipeline.details.status.group) {
        eventHub.$emit('MRWidgetUpdateRequested');
      } else {
        // TODO: Make sure `this.pipeline.details.status` always exists before access it.
        this.pipeline.coverage = data.coverage;
        this.pipeline.details.status.group = newStatus;
        this.pipeline.details.stages = data.stages;
      }
    }
  }

  static getAuthorObject(event) {
    if (!event) {
      return {};
    }

    return {
      name: event.author.name || '',
      username: event.author.username || '',
      webUrl: event.author.web_url || '',
      avatarUrl: event.author.avatar_url || '',
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
