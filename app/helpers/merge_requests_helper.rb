module MergeRequestsHelper
  def new_mr_path_from_push_event(event)
    target_project = event.project.forked_from_project || event.project
    new_namespace_project_merge_request_path(
      event.project.namespace,
      event.project,
      new_mr_from_push_event(event, target_project)
    )
  end

  def new_mr_from_push_event(event, target_project)
    {
      merge_request: {
        source_project_id: event.project.id,
        target_project_id: target_project.id,
        source_branch: event.branch_name,
        target_branch: target_project.repository.root_ref
      }
    }
  end

  def mr_css_classes(mr)
    classes = "merge-request"
    classes << " closed" if mr.closed?
    classes << " merged" if mr.merged?
    classes
  end

  def ci_build_details_path(merge_request)
    build_url = merge_request.source_project.ci_service.build_page(merge_request.diff_head_sha, merge_request.source_branch)
    return nil unless build_url

    parsed_url = URI.parse(build_url)

    unless parsed_url.userinfo.blank?
      parsed_url.userinfo = ''
    end

    parsed_url.to_s
  end

  def merge_path_description(merge_request, separator)
    if merge_request.for_fork?
      "Project:Branches: #{@merge_request.source_project_path}:#{@merge_request.source_branch} #{separator} #{@merge_request.target_project.path_with_namespace}:#{@merge_request.target_branch}"
    else
      "Branches: #{@merge_request.source_branch} #{separator} #{@merge_request.target_branch}"
    end
  end

  # TODO: Remove when moving mr_change_branches_path data to MR serializer
  def issues_sentence(issues)
    # Sorting based on the `#123` or `group/project#123` reference will sort
    # local issues first.
    issues.map do |issue|
      issue.to_reference(@project)
    end.sort.to_sentence
  end

  # TODO: Remove when mr_assign_issues_link data goes to MR serializer
  def mr_closes_issues
    @mr_closes_issues ||= @merge_request.closes_issues(current_user)
  end

  # TODO: Move to MR serializer
  def mr_assign_issues_link
    issues = MergeRequests::AssignIssuesService.new(@project,
                                                    current_user,
                                                    merge_request: @merge_request,
                                                    closes_issues: mr_closes_issues
                                                   ).assignable_issues
    path = assign_related_issues_namespace_project_merge_request_path(@project.namespace, @project, @merge_request)
    if issues.present?
      pluralize_this_issue = issues.count > 1 ? "these issues" : "this issue"
      link_to "Assign yourself to #{pluralize_this_issue}", path, method: :post
    end
  end

  def mr_change_branches_path(merge_request)
    new_namespace_project_merge_request_path(
      @project.namespace, @project,
      merge_request: {
        source_project_id: merge_request.source_project_id,
        target_project_id: merge_request.target_project_id,
        source_branch: merge_request.source_branch,
        target_branch: merge_request.target_branch,
      },
      change_branches: true
    )
  end

  def source_branch_with_namespace(merge_request)
    namespace = merge_request.source_project_namespace
    branch = merge_request.source_branch

    if merge_request.source_branch_exists?
      namespace = link_to(namespace, project_path(merge_request.source_project))
      branch = link_to(branch, namespace_project_commits_path(merge_request.source_project.namespace, merge_request.source_project, merge_request.source_branch))
    end

    if merge_request.for_fork?
      namespace + ":" + branch
    else
      branch
    end
  end

  def format_mr_branch_names(merge_request)
    source_path = merge_request.source_project_path
    target_path = merge_request.target_project_path
    source_branch = merge_request.source_branch
    target_branch = merge_request.target_branch

    if source_path == target_path
      [source_branch, target_branch]
    else
      ["#{source_path}:#{source_branch}", "#{target_path}:#{target_branch}"]
    end
  end

  def merge_request_button_visibility(merge_request, closed)
    return 'hidden' if merge_request.closed? == closed || (merge_request.merged? == closed && !merge_request.closed?) || merge_request.closed_without_fork?
  end

  def merge_request_version_path(project, merge_request, merge_request_diff, start_sha = nil)
    diffs_namespace_project_merge_request_path(
      project.namespace, project, merge_request,
      diff_id: merge_request_diff.id, start_sha: start_sha)
  end

  def version_index(merge_request_diff)
    @merge_request_diffs.size - @merge_request_diffs.index(merge_request_diff)
  end

  def different_base?(version1, version2)
    version1 && version2 && version1.base_commit_sha != version2.base_commit_sha
  end

  def merge_params(merge_request)
    {
      merge_when_pipeline_succeeds: true,
      should_remove_source_branch: true,
      sha: merge_request.diff_head_sha
    }.merge(merge_params_ee(merge_request))
  end

  def merge_params_ee(merge_request)
    {}
  end
end
