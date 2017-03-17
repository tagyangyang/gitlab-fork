# rubocop:disable all
class EnableSslVerificationByDefault < ActiveRecord::Migration
  DOWNTIME = false

  def up
    change_column :web_hooks, :enable_ssl_verification, :boolean, default: true
  end

  def down
    change_column :web_hooks, :enable_ssl_verification, :boolean, default: false
  end
end
