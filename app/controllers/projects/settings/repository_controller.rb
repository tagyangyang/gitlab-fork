module Projects
  module Settings
    class RepositoryController < Projects::ApplicationController
      before_action :authorize_admin_project!

      def show
        @deploy_keys = DeployKeysPresenter
          .new(@project, current_user: current_user)

        define_protected_refs
      end

      private

      def define_protected_refs
        load_protected_branches
        # load_protected_tags
        @protected_branch = @project.protected_branches.new
        # @protected_tag = @project.protected_tags.new
        load_gon_index
      end

      def load_protected_branches
        @protected_branches = @project.protected_branches.order(:name).page(params[:page])
      end

      # def load_protected_tags
      #   @protected_tags = @project.protected_tags.order(:name).page(params[:page])
      # end

      def access_levels_options
        #TODO: consider protected tags
        {
          push_access_levels: {
            roles: ProtectedBranch::PushAccessLevel.human_access_levels.map do |id, text|
              { id: id, text: text, before_divider: true }
            end
          },
          merge_access_levels: {
            roles: ProtectedBranch::MergeAccessLevel.human_access_levels.map do |id, text|
              { id: id, text: text, before_divider: true }
            end
          }
        }
      end

      def open_branches
        branches = @project.open_branches.map { |br| { text: br.name, id: br.name, title: br.name } }
        { open_branches: branches }
      end

      def load_gon_index
        #TODO: consider protected tags
        gon.push(open_branches.merge(access_levels_options))
      end
    end
  end
end
