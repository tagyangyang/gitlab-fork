module API
  class Issues < Grape::API
    include PaginationParams

    before { authenticate! }

    helpers do
      def find_issues(args = {})
        args = params.merge(args)

        args.delete(:id)
        args[:milestone_title] = args.delete(:milestone)
        args[:label_name] = args.delete(:labels)

        issues = IssuesFinder.new(current_user, args).execute

        issues.reorder(args[:order_by] => args[:sort])
      end

      params :issues_params do
        optional :labels, type: String, desc: 'Comma-separated list of label names'
        optional :milestone, type: String, desc: 'Milestone title'
        optional :order_by, type: String, values: %w[created_at updated_at], default: 'created_at',
                            desc: 'Return issues ordered by `created_at` or `updated_at` fields.'
        optional :sort, type: String, values: %w[asc desc], default: 'desc',
                        desc: 'Return issues sorted in `asc` or `desc` order.'
        optional :milestone, type: String, desc: 'Return issues for a specific milestone'
        optional :iids, type: Array[Integer], desc: 'The IID array of issues'
        optional :search, type: String, desc: 'Search issues for text present in the title or description'
        use :pagination
      end

      params :issue_params do
        optional :description, type: String, desc: 'The description of an issue'
        optional :assignee_id, type: Integer, desc: 'The ID of a user to assign issue'
        optional :milestone_id, type: Integer, desc: 'The ID of a milestone to assign issue'
        optional :labels, type: String, desc: 'Comma-separated list of label names'
        optional :due_date, type: String, desc: 'Date time string in the format YEAR-MONTH-DAY'
        optional :confidential, type: Boolean, desc: 'Boolean parameter if the issue should be confidential'
      end
    end

    resource :issues do
      desc "Get currently authenticated user's issues" do
        success Entities::IssueBasic
      end
      params do
        optional :state, type: String, values: %w[opened closed all], default: 'all',
                         desc: 'Return opened, closed, or all issues'
        use :issues_params
      end
      get do
        issues = find_issues(scope: 'authored')

        present paginate(issues), with: Entities::IssueBasic, current_user: current_user
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a group'
    end
    resource :groups, requirements: { id: %r{[^/]+} } do
      desc 'Get a list of group issues' do
        success Entities::IssueBasic
      end
      params do
        optional :state, type: String, values: %w[opened closed all], default: 'all',
                         desc: 'Return opened, closed, or all issues'
        use :issues_params
      end
      get ":id/issues" do
        group = find_group!(params[:id])

        issues = find_issues(group_id: group.id)

        present paginate(issues), with: Entities::IssueBasic, current_user: current_user
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: { id: %r{[^/]+} } do
      include TimeTrackingEndpoints

      desc 'Get a list of project issues' do
        success Entities::IssueBasic
      end
      params do
        optional :state, type: String, values: %w[opened closed all], default: 'all',
                         desc: 'Return opened, closed, or all issues'
        use :issues_params
      end
      get ":id/issues" do
        project = find_project!(params[:id])

        issues = find_issues(project_id: project.id)

        present paginate(issues), with: Entities::IssueBasic, current_user: current_user, project: user_project
      end

      desc 'Get a single project issue' do
        success Entities::Issue
      end
      params do
        requires :issue_iid, type: Integer, desc: 'The internal ID of a project issue'
      end
      get ":id/issues/:issue_iid" do
        issue = find_project_issue(params[:issue_iid])
        present issue, with: Entities::Issue, current_user: current_user, project: user_project
      end

      desc 'Create a new project issue' do
        success Entities::Issue
      end
      params do
        requires :title, type: String, desc: 'The title of an issue'
        optional :created_at, type: DateTime,
                              desc: 'Date time when the issue was created. Available only for admins and project owners.'
        optional :merge_request_to_resolve_discussions_of, type: Integer,
                                                           desc: 'The IID of a merge request for which to resolve discussions'
        optional :discussion_to_resolve, type: String,
                                         desc: 'The ID of a discussion to resolve, also pass `merge_request_to_resolve_discussions_of`'
        use :issue_params
      end
      post ':id/issues' do
        # Setting created_at time only allowed for admins and project owners
        unless current_user.admin? || user_project.owner == current_user
          params.delete(:created_at)
        end

        issue_params = declared_params(include_missing: false)

        issue = ::Issues::CreateService.new(user_project,
                                            current_user,
                                            issue_params.merge(request: request, api: true)).execute
        if issue.spam?
          render_api_error!({ error: 'Spam detected' }, 400)
        end

        if issue.valid?
          present issue, with: Entities::Issue, current_user: current_user, project: user_project
        else
          render_validation_error!(issue)
        end
      end

      desc 'Update an existing issue' do
        success Entities::Issue
      end
      params do
        requires :issue_iid, type: Integer, desc: 'The internal ID of a project issue'
        optional :title, type: String, desc: 'The title of an issue'
        optional :updated_at, type: DateTime,
                              desc: 'Date time when the issue was updated. Available only for admins and project owners.'
        optional :state_event, type: String, values: %w[reopen close], desc: 'State of the issue'
        use :issue_params
        at_least_one_of :title, :description, :assignee_id, :milestone_id,
                        :labels, :created_at, :due_date, :confidential, :state_event
      end
      put ':id/issues/:issue_iid' do
        issue = user_project.issues.find_by!(iid: params.delete(:issue_iid))
        authorize! :update_issue, issue

        # Setting created_at time only allowed for admins and project owners
        unless current_user.admin? || user_project.owner == current_user
          params.delete(:updated_at)
        end

        update_params = declared_params(include_missing: false).merge(request: request, api: true)

        issue = ::Issues::UpdateService.new(user_project,
                                            current_user,
                                            update_params).execute(issue)

        render_spam_error! if issue.spam?

        if issue.valid?
          present issue, with: Entities::Issue, current_user: current_user, project: user_project
        else
          render_validation_error!(issue)
        end
      end

      desc 'Move an existing issue' do
        success Entities::Issue
      end
      params do
        requires :issue_iid, type: Integer, desc: 'The internal ID of a project issue'
        requires :to_project_id, type: Integer, desc: 'The ID of the new project'
      end
      post ':id/issues/:issue_iid/move' do
        issue = user_project.issues.find_by(iid: params[:issue_iid])
        not_found!('Issue') unless issue

        new_project = Project.find_by(id: params[:to_project_id])
        not_found!('Project') unless new_project

        begin
          issue = ::Issues::MoveService.new(user_project, current_user).execute(issue, new_project)
          present issue, with: Entities::Issue, current_user: current_user, project: user_project
        rescue ::Issues::MoveService::MoveError => error
          render_api_error!(error.message, 400)
        end
      end

      desc 'Delete a project issue'
      params do
        requires :issue_iid, type: Integer, desc: 'The internal ID of a project issue'
      end
      delete ":id/issues/:issue_iid" do
        issue = user_project.issues.find_by(iid: params[:issue_iid])
        not_found!('Issue') unless issue

        authorize!(:destroy_issue, issue)
        issue.destroy
      end
    end
  end
end
