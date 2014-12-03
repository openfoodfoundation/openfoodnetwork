class AddOwnerToEnterprise < ActiveRecord::Migration
  def up
    add_column :enterprises, :owner_id, :integer
    add_index :enterprises, :owner_id

    Enterprise.all.each do |e|
      owner = e.users.find{ |u| !u.admin? }
      admin_owner = e.users.find &:admin?
      any_admin = Spree::User.admin.first
      any_user = Spree::User.first
      any_user ||= Spree::User.new(email: 'owner@example.com', password: 'owner123').tap { |u| u.save(validate: false) }
      e.update_column :owner_id, (owner || admin_owner || any_admin || any_user )
    end

    add_foreign_key :enterprises, :spree_users, column: :owner_id
    change_column :enterprises, :owner_id, :integer, null: false
  end

  def down
    remove_column :enterprises, :owner_id
  end
end
