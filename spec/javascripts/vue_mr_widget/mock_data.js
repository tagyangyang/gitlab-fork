export default {
  "id": 130,
  "iid": 20,
  "assignee_id": null,
  "author_id": 1,
  "description": "",
  "lock_version": null,
  "milestone_id": null,
  "position": 0,
  "state": "merged",
  "title": "Update README.md",
  "updated_by_id": null,
  "created_at": "2017-04-06T21:41:52.008Z",
  "updated_at": "2017-04-06T21:42:12.922Z",
  "deleted_at": null,
  "time_estimate": 0,
  "total_time_spent": 0,
  "human_time_estimate": null,
  "human_total_time_spent": null,
  "in_progress_merge_commit_sha": null,
  "locked_at": null,
  "merge_commit_sha": "f0d4b917473e4c67e5a2bf14f372b189c8442903",
  "merge_error": null,
  "merge_params": {
    "force_remove_source_branch": null
  },
  "merge_status": "can_be_merged",
  "merge_user_id": null,
  "merge_when_pipeline_succeeds": false,
  "source_branch": "foo",
  "source_project_id": 19,
  "target_branch": "master",
  "target_project_id": 19,
  "merge_event": {
    "author": {
      "name": "Administrator",
      "username": "root",
      "id": 1,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://localhost:3000/root"
    },
    "updated_at": "2017-04-06T21:42:12.837Z"
  },
  "closed_event": null,
  "author": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://localhost:3000/root"
  },
  "merge_user": null,
  "diff_head_sha": "06d41f0e185c2a6754739fd027ff1f8944cc77e0",
  "diff_head_commit_short_id": "06d41f0e",
  "merge_commit_message": "Merge branch 'foo' into 'master'\n\nUpdate README.md\n\nSee merge request !20",
  "pipeline": {
    "id": 167,
    "user": {
      "name": "Administrator",
      "username": "root",
      "id": 1,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://localhost:3000/root"
    },
    "active": false,
    "coverage": null,
    "path": "/root/acets-branch/pipelines/167",
    "details": {
      "status": {
        "icon": "icon_status_success",
        "favicon": "favicon_status_success",
        "text": "passed",
        "label": "passed",
        "group": "success",
        "has_details": true,
        "details_path": "/root/acets-branch/pipelines/167"
      },
      "duration": null,
      "finished_at": null,
      "stages": [
        {
          "name": "build",
          "title": "build: pending",
          "status": {
            "icon": "icon_status_pending",
            "favicon": "favicon_status_pending",
            "text": "pending",
            "label": "pending",
            "group": "pending",
            "has_details": true,
            "details_path": "/root/acets-branch/pipelines/167#build"
          },
          "path": "/root/acets-branch/pipelines/167#build",
          "dropdown_path": "/root/acets-branch/pipelines/167/stage.json?stage=build"
        },
        {
          "name": "review",
          "title": "review: created",
          "status": {
            "icon": "icon_status_created",
            "favicon": "favicon_status_created",
            "text": "created",
            "label": "created",
            "group": "created",
            "has_details": true,
            "details_path": "/root/acets-branch/pipelines/167#review"
          },
          "path": "/root/acets-branch/pipelines/167#review",
          "dropdown_path": "/root/acets-branch/pipelines/167/stage.json?stage=review"
        }
      ],
      "artifacts": [

      ],
      "manual_actions": [

      ]
    },
    "flags": {
      "latest": false,
      "triggered": false,
      "stuck": true,
      "yaml_errors": false,
      "retryable": false,
      "cancelable": true
    },
    "ref": {
      "name": "foo",
      "path": "/root/acets-branch/tree/foo",
      "tag": false,
      "branch": true
    },
    "commit": {
      "id": "06d41f0e185c2a6754739fd027ff1f8944cc77e0",
      "short_id": "06d41f0e",
      "title": "Update README.md",
      "created_at": "2017-04-07T00:41:47.000+03:00",
      "parent_ids": [
        "cf221f42c5cd3bb13691dd935ef0a01f2b4b03b4"
      ],
      "message": "Update README.md",
      "author_name": "Administrator",
      "author_email": "admin@example.com",
      "authored_date": "2017-04-07T00:41:47.000+03:00",
      "committer_name": "Administrator",
      "committer_email": "admin@example.com",
      "committed_date": "2017-04-07T00:41:47.000+03:00",
      "author": {
        "name": "Administrator",
        "username": "root",
        "id": 1,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
        "web_url": "http://localhost:3000/root"
      },
      "author_gravatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "commit_url": "http://localhost:3000/root/acets-branch/commit/06d41f0e185c2a6754739fd027ff1f8944cc77e0",
      "commit_path": "/root/acets-branch/commit/06d41f0e185c2a6754739fd027ff1f8944cc77e0"
    },
    "cancel_path": "/root/acets-branch/pipelines/167/cancel",
    "created_at": "2017-04-06T21:41:48.015Z",
    "updated_at": "2017-04-06T21:41:59.475Z"
  },
  "work_in_progress": false,
  "source_branch_exists": false,
  "mergeable_discussions_state": true,
  "conflicts_can_be_resolved_in_ui": false,
  "branch_missing": true,
  "has_no_commits": false,
  "can_be_cherry_picked": {
    "id": "f0d4b917473e4c67e5a2bf14f372b189c8442903",
    "message": "Merge branch 'foo' into 'master'\n\nUpdate README.md\n\nSee merge request !20",
    "parent_ids": [
      "cf221f42c5cd3bb13691dd935ef0a01f2b4b03b4",
      "06d41f0e185c2a6754739fd027ff1f8944cc77e0"
    ],
    "authored_date": "2017-04-07T00:42:11.000+03:00",
    "author_name": "Administrator",
    "author_email": "admin@example.com",
    "committed_date": "2017-04-07T00:42:11.000+03:00",
    "committer_name": "Administrator",
    "committer_email": "admin@example.com"
  },
  "has_conflicts": false,
  "can_be_merged": true,
  "has_ci": true,
  "ci_status": "success",
  "pipeline_status_path": "/root/acets-branch/merge_requests/20/pipeline_status",
  "issues_links": {
    "closing": "",
    "mentioned_but_not_closing": ""
  },
  "current_user": {
    "can_create_issue": true,
    "can_update_merge_request": true,
    "can_resolve_conflicts": true,
    "can_remove_source_branch": false,
    "can_merge": true,
    "can_merge_via_cli": true,
    "can_revert": true,
    "can_cancel_automatic_merge": true,
    "can_collaborate_with_project": true,
    "can_fork_project": true,
    "cherry_pick_in_fork_path": "/root/acets-branch/forks?continue%5Bnotice%5D=You%27re+not+allowed+to+make+changes+to+this+project+directly.+A+fork+of+this+project+has+been+created+that+you+can+make+changes+in%2C+so+you+can+submit+a+merge+request.+Try+to+cherry-pick+this+commit+again.&continue%5Bnotice_now%5D=You%27re+not+allowed+to+make+changes+to+this+project+directly.+A+fork+of+this+project+is+being+created+that+you+can+make+changes+in%2C+so+you+can+submit+a+merge+request.&continue%5Bto%5D=%2Froot%2Facets-branch%2Fmerge_requests%2F20&namespace_key=1",
    "revert_in_fork_path": "/root/acets-branch/forks?continue%5Bnotice%5D=You%27re+not+allowed+to+make+changes+to+this+project+directly.+A+fork+of+this+project+has+been+created+that+you+can+make+changes+in%2C+so+you+can+submit+a+merge+request.+Try+to+revert+this+commit+again.&continue%5Bnotice_now%5D=You%27re+not+allowed+to+make+changes+to+this+project+directly.+A+fork+of+this+project+is+being+created+that+you+can+make+changes+in%2C+so+you+can+submit+a+merge+request.&continue%5Bto%5D=%2Froot%2Facets-branch%2Fmerge_requests%2F20&namespace_key=1"
  },
  "target_branch_path": "/root/acets-branch/branches/master",
  "source_branch_path": "/root/acets-branch/branches/foo",
  "project_archived": false,
  "conflict_resolution_ui_path": "/root/acets-branch/merge_requests/20/conflicts",
  "remove_wip_path": "/root/acets-branch/merge_requests/20/remove_wip",
  "merge_path": "/root/acets-branch/merge_requests/20/merge",
  "cancel_merge_when_pipeline_succeeds_path": "/root/acets-branch/merge_requests/20/cancel_merge_when_pipeline_succeeds",
  "merge_commit_message_with_description": "Merge branch 'foo' into 'master'\n\nUpdate README.md\n\nSee merge request !20",
  "diverged_commits_count": 0,
  "email_patches_path": "/root/acets-branch/merge_requests/20.patch",
  "plain_diff_path": "/root/acets-branch/merge_requests/20.diff",
  "ci_status_path": "/root/acets-branch/merge_requests/20/ci_status",
  "status_path": "/root/acets-branch/merge_requests/20.json",
  "merge_check_path": "/root/acets-branch/merge_requests/20/merge_check",
  "only_allow_merge_if_pipeline_succeeds": false,
  "create_issue_to_resolve_discussions_path": "/root/acets-branch/issues/new?merge_request_for_resolving_discussions_of=20",
  "ci_environments_status_url": "/root/acets-branch/merge_requests/20/ci_environments_status",
  "commit_change_content_path": "/root/acets-branch/merge_requests/20/commit_change_content"
};
