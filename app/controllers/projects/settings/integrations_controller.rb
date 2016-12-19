module Projects
  module Settings
    class IntegrationsController < Projects::ApplicationController
      def show
        @hooks = @project.hooks
        @hook = ProjectHook.new

        @services = @project.find_or_initialize_services
      end
    end
  end
end
