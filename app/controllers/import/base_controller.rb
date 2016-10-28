class Import::BaseController < ApplicationController
  private

  def find_or_create_namespace
    path = params[:target_namespace]

    return current_user.namespace if path == current_user.namespace_path

    owned_namespace = current_user.owned_groups.find_by(path: path)
    return owned_namespace if owned_namespace

    return current_user.namespace unless current_user.can_create_group?

    begin
      namespace = Group.create!(name: path, path: path, owner: current_user)
      namespace.add_owner(current_user)
      namespace
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
      current_user.namespace
    end
  end
end
