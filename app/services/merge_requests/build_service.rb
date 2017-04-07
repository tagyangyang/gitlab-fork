module MergeRequests
  class BuildService < MergeRequests::BaseService
    def execute
      self.merge_request = MergeRequest.new(params)
      merge_request.compare_commits = []
      merge_request.source_project  = find_source_project
      merge_request.target_project  = find_target_project
      merge_request.target_branch   = find_target_branch
      merge_request.can_be_created  = branches_valid?

      compare_branches if branches_present?
      assign_title_and_description if merge_request.can_be_created

      merge_request
    end

    private

    attr_accessor :merge_request

    delegate :target_branch, :source_branch, :source_project, :target_project, :compare_commits, :wip_title, :description, :errors, to: :merge_request

    def find_source_project
      return source_project if source_project.present? && can?(current_user, :read_project, source_project)

      project
    end

    def find_target_project
      return target_project if target_project.present? && can?(current_user, :read_project, target_project)
      project.forked_from_project || project
    end

    def find_target_branch
      target_branch || target_project.default_branch
    end

    def source_branch_specified?
      params[:source_branch].present?
    end

    def target_branch_specified?
      params[:target_branch].present?
    end

    def branches_valid?
      return false unless source_branch_specified? || target_branch_specified?

      validate_branches
      errors.blank?
    end

    def compare_branches
      compare = CompareService.new(
        source_project,
        source_branch
      ).execute(
        target_project,
        target_branch
      )

      if compare
        merge_request.compare_commits = compare.commits
        merge_request.compare = compare
      end
    end

    def validate_branches
      add_error('You must select source and target branch') unless branches_present?
      add_error('You must select different branches') if same_source_and_target?
      add_error("Source branch \"#{source_branch}\" does not exist") unless source_branch_exists?
      add_error("Target branch \"#{target_branch}\" does not exist") unless target_branch_exists?
    end

    def add_error(message)
      errors.add(:base, message)
    end

    def branches_present?
      target_branch.present? && source_branch.present?
    end

    def same_source_and_target?
      source_project == target_project && target_branch == source_branch
    end

    def source_branch_exists?
      source_branch.blank? || source_project.commit(source_branch)
    end

    def target_branch_exists?
      target_branch.blank? || target_project.commit(target_branch)
    end

    # When your branch name starts with an iid followed by a dash this pattern will be
    # interpreted as the user wants to close that issue on this project.
    #
    # For example:
    # - Issue 112 exists, title: Emoji don't show up in commit title
    # - Source branch is: 112-fix-mep-mep
    #
    # Will lead to:
    # - Appending `Closes #112` to the description
    # - Setting the title as 'Resolves "Emoji don't show up in commit title"' if there is
    #   more than one commit in the MR
    #
    def assign_title_and_description
      if match = source_branch.match(/\A(\d+)-/)
        iid = match[1]
      end

      commits = compare_commits
      if commits && commits.count == 1
        commit = commits.first
        merge_request.title = commit.title
        merge_request.description ||= commit.description.try(:strip)
      elsif iid && issue = target_project.get_issue(iid, current_user)
        case issue
        when Issue
          merge_request.title = "Resolve \"#{issue.title}\""
        when ExternalIssue
          merge_request.title = "Resolve #{issue.title}"
        end
      else
        merge_request.title = source_branch.titleize.humanize
      end

      if iid
        closes_issue = "Closes ##{iid}"

        if description.present?
          merge_request.description += closes_issue.prepend("\n\n")
        else
          merge_request.description = closes_issue
        end
      end

      merge_request.title = wip_title if commits.empty?
    end
  end
end
