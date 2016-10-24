class Projects::CustomEmojiController < Projects::ApplicationController
  before_action :authorize_read_custom_emoji!
  before_action :authorize_admin_custom_emoji!, only: [:new, :create, :destroy]

  respond_to :html

  def index
    @custom_emoji = project.custom_emoji.page(params[:page])
  end

  def new
    @custom_emoji = project.custom_emoji.new
  end

  def create
    @custom_emoji = project.custom_emoji.create(custom_emoji_params)

    if @custom_emoji.persisted?
      # TODO, I don't know wether this will work or not, but lets go to the index
      # page, maybe have the new form right there
      redirect_to namespace_project_custom_emoji_index_path(project.namespace, project)
    else
      render :new
    end
  end

  def edit
  end

  def destroy
    project.custom_emoji.find(params[:id]).destroy

    redirect_to(namespace_project_labels_path(project.namespace, project),
                    notice: 'Custom Emoji was removed')
  end

  protected

  def custom_emoji_params
    params.require(:custom_emoji).permit(:name, :emoji)
  end

  def authorize_admin_labels!
    return render_404 unless can?(current_user, :admin_label, @project)
  end
end
