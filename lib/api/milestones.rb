module API
  class Milestones < Grape::API
    include PaginationParams

    before { authenticate! }

    helpers do
      def filter_milestones_state(milestones, state)
        case state
        when 'active' then milestones.active
        when 'closed' then milestones.closed
        else milestones
        end
      end

      params :optional_params do
        optional :description, type: String, desc: 'The description of the milestone'
        optional :due_date, type: String, desc: 'The due date of the milestone. The ISO 8601 date format (%Y-%m-%d)'
        optional :start_date, type: String, desc: 'The start date of the milestone. The ISO 8601 date format (%Y-%m-%d)'
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: { id: %r{[^/]+} } do
      desc 'Get a list of project milestones' do
        success Entities::Milestone
      end
      params do
        optional :state, type: String, values: %w[active closed all], default: 'all',
                         desc: 'Return "active", "closed", or "all" milestones'
        optional :iids, type: Array[Integer], desc: 'The IIDs of the milestones'
        optional :search, type: String, desc: 'The search criteria for the title or description of the milestone'
        use :pagination
      end
      get ":id/milestones" do
        authorize! :read_milestone, user_project

        milestones = user_project.milestones
        milestones = filter_milestones_state(milestones, params[:state])
        milestones = filter_by_iid(milestones, params[:iids]) if params[:iids].present?
        milestones = filter_by_search(milestones, params[:search]) if params[:search]

        present paginate(milestones), with: Entities::Milestone
      end

      desc 'Get a single project milestone' do
        success Entities::Milestone
      end
      params do
        requires :milestone_id, type: Integer, desc: 'The ID of a project milestone'
      end
      get ":id/milestones/:milestone_id" do
        authorize! :read_milestone, user_project

        milestone = user_project.milestones.find(params[:milestone_id])
        present milestone, with: Entities::Milestone
      end

      desc 'Create a new project milestone' do
        success Entities::Milestone
      end
      params do
        requires :title, type: String, desc: 'The title of the milestone'
        use :optional_params
      end
      post ":id/milestones" do
        authorize! :admin_milestone, user_project

        milestone = ::Milestones::CreateService.new(user_project, current_user, declared_params).execute

        if milestone.valid?
          present milestone, with: Entities::Milestone
        else
          render_api_error!("Failed to create milestone #{milestone.errors.messages}", 400)
        end
      end

      desc 'Update an existing project milestone' do
        success Entities::Milestone
      end
      params do
        requires :milestone_id, type: Integer, desc: 'The ID of a project milestone'
        optional :title, type: String, desc: 'The title of the milestone'
        optional :state_event, type: String, values: %w[close activate],
                               desc: 'The state event of the milestone '
        use :optional_params
        at_least_one_of :title, :description, :due_date, :state_event
      end
      put ":id/milestones/:milestone_id" do
        authorize! :admin_milestone, user_project
        milestone = user_project.milestones.find(params.delete(:milestone_id))

        milestone_params = declared_params(include_missing: false)
        milestone = ::Milestones::UpdateService.new(user_project, current_user, milestone_params).execute(milestone)

        if milestone.valid?
          present milestone, with: Entities::Milestone
        else
          render_api_error!("Failed to update milestone #{milestone.errors.messages}", 400)
        end
      end

      desc 'Get all issues for a single project milestone' do
        success Entities::IssueBasic
      end
      params do
        requires :milestone_id, type: Integer, desc: 'The ID of a project milestone'
        use :pagination
      end
      get ":id/milestones/:milestone_id/issues" do
        authorize! :read_milestone, user_project

        milestone = user_project.milestones.find(params[:milestone_id])

        finder_params = {
          project_id: user_project.id,
          milestone_title: milestone.title,
          sort: 'position_asc'
        }

        issues = IssuesFinder.new(current_user, finder_params).execute
        present paginate(issues), with: Entities::IssueBasic, current_user: current_user, project: user_project
      end

      desc 'Get all merge requests for a single project milestone' do
        detail 'This feature was introduced in GitLab 9.'
        success Entities::MergeRequestBasic
      end
      params do
        requires :milestone_id, type: Integer, desc: 'The ID of a project milestone'
        use :pagination
      end
      get ':id/milestones/:milestone_id/merge_requests' do
        authorize! :read_milestone, user_project

        milestone = user_project.milestones.find(params[:milestone_id])

        finder_params = {
          project_id: user_project.id,
          milestone_title: milestone.title,
          sort: 'position_asc'
        }

        merge_requests = MergeRequestsFinder.new(current_user, finder_params).execute
        present paginate(merge_requests),
          with: Entities::MergeRequestBasic,
          current_user: current_user,
          project: user_project
      end
    end
  end
end
