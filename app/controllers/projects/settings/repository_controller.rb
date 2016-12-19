module Projects
  module Settings
    class RepositoryController < Projects::ApplicationController
      include ProtectedBranchesHelper

      def show
        @key = DeployKey.new
        @protected_branch = @project.protected_branches.new
        @protected_branches = @project.protected_branches.order(:name).page(params[:page])
        set_index_vars
        load_gon_index(@project)
      end

      def set_index_vars
        @enabled_keys           ||= @project.deploy_keys

        @available_keys         ||= current_user.accessible_deploy_keys - @enabled_keys
        @available_project_keys ||= current_user.project_deploy_keys - @enabled_keys
        @available_public_keys  ||= DeployKey.are_public - @enabled_keys

        # Public keys that are already used by another accessible project are already
        # in @available_project_keys.
        @available_public_keys -= @available_project_keys
      end
    end
  end
end
