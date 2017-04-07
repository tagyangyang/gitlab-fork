# Controller for viewing a file's blame
class Projects::BlobController < Projects::ApplicationController
  include ExtractsPath
  include CreatesCommit
  include ActionView::Helpers::SanitizeHelper

  # Raised when given an invalid file path
  InvalidPathError = Class.new(StandardError)

  prepend_before_action :authenticate_user!, only: [:edit]

  before_action :require_non_empty_project, except: [:new, :create]
  before_action :authorize_download_code!
  before_action :authorize_edit_tree!, only: [:new, :create, :update, :destroy]
  before_action :assign_blob_vars
  before_action :commit, except: [:new, :create]
  before_action :blob, except: [:new, :create]
  before_action :require_branch_head, only: [:edit, :update]
  before_action :editor_variables, except: [:show, :preview, :diff]
  before_action :validate_diff_params, only: :diff
  before_action :set_last_commit_sha, only: [:edit, :update]

  def new
    commit unless @repository.empty?
  end

  def create
    update_ref

    create_commit(Files::CreateService, success_notice: "The file has been successfully created.",
                                        success_path: -> { namespace_project_blob_path(@project.namespace, @project, File.join(@target_branch, @file_path)) },
                                        failure_view: :new,
                                        failure_path: namespace_project_new_blob_path(@project.namespace, @project, @ref))
  end

  def show
    environment_params = @repository.branch_exists?(@ref) ? { ref: @ref } : { commit: @commit }
    @environment = EnvironmentsFinder.new(@project, current_user, environment_params).execute.last
  end

  def edit
    if can_collaborate_with_project?
      blob.load_all_data!(@repository)
    else
      redirect_to action: 'show'
    end
  end

  def update
    @path = params[:file_path] if params[:file_path].present?
    create_commit(Files::UpdateService, success_path: -> { after_edit_path },
                                        failure_view: :edit,
                                        failure_path: namespace_project_blob_path(@project.namespace, @project, @id))

  rescue Files::UpdateService::FileChangedError
    @conflict = true
    render :edit
  end

  def preview
    @content = params[:content]
    @blob.load_all_data!(@repository)
    diffy = Diffy::Diff.new(@blob.data, @content, diff: '-U 3', include_diff_info: true)
    diff_lines = diffy.diff.scan(/.*\n/)[2..-1]
    diff_lines = Gitlab::Diff::Parser.new.parse(diff_lines)
    @diff_lines = Gitlab::Diff::Highlight.new(diff_lines, repository: @repository).highlight

    render layout: false
  end

  def destroy
    create_commit(Files::DestroyService, success_notice: "The file has been successfully deleted.",
                                         success_path: -> { namespace_project_tree_path(@project.namespace, @project, @target_branch) },
                                         failure_view: :show,
                                         failure_path: namespace_project_blob_path(@project.namespace, @project, @id))
  end

  def diff
    apply_diff_view_cookie!

    @form  = UnfoldForm.new(params)
    @lines = Gitlab::Highlight.highlight_lines(repository, @ref, @path)
    @lines = @lines[@form.since - 1..@form.to - 1]

    if @form.bottom?
      @match_line = ''
    else
      lines_length = @lines.length - 1
      line = [@form.since, lines_length].join(',')
      @match_line = "@@ -#{line}+#{line} @@"
    end

    render layout: false
  end

  private

  def blob
    @blob ||= Blob.decorate(@repository.blob_at(@commit.id, @path))

    if @blob
      @blob
    else
      if tree = @repository.tree(@commit.id, @path)
        if tree.entries.any?
          return redirect_to namespace_project_tree_path(@project.namespace, @project, File.join(@ref, @path))
        end
      end

      return render_404
    end
  end

  def commit
    @commit = @repository.commit(@ref)

    return render_404 unless @commit
  end

  def assign_blob_vars
    @id = params[:id]
    @ref, @path = extract_ref(@id)

  rescue InvalidPathError
    render_404
  end

  def after_edit_path
    from_merge_request = MergeRequestsFinder.new(current_user, project_id: @project.id).execute.find_by(iid: params[:from_merge_request_iid])
    if from_merge_request && @target_branch == @ref
      diffs_namespace_project_merge_request_path(from_merge_request.target_project.namespace, from_merge_request.target_project, from_merge_request) +
        "##{hexdigest(@path)}"
    else
      namespace_project_blob_path(@project.namespace, @project, File.join(@target_branch, @path))
    end
  end

  def editor_variables
    @target_branch = params[:target_branch]

    @file_path =
      if action_name.to_s == 'create'
        if params[:file].present?
          params[:file_name] = params[:file].original_filename
        end
        File.join(@path, params[:file_name])
      elsif params[:file_path].present?
        params[:file_path]
      else
        @path
      end

    if params[:file].present?
      params[:content] = Base64.encode64(params[:file].read)
      params[:encoding] = 'base64'
    end

    @commit_params = {
      file_path: @file_path,
      commit_message: params[:commit_message],
      previous_path: @path,
      file_content: params[:content],
      file_content_encoding: params[:encoding],
      last_commit_sha: params[:last_commit_sha]
    }
  end

  def validate_diff_params
    if [:since, :to, :offset].any? { |key| params[key].blank? }
      render nothing: true
    end
  end

  def set_last_commit_sha
    @last_commit_sha = Gitlab::Git::Commit.
      last_for_path(@repository, @ref, @path).sha
  end
end
