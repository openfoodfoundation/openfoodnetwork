class AddSocialMediaToEnterprises < ActiveRecord::Migration
  def change
    add_column :enterprises, :facebook, :string
    add_column :enterprises, :instagram, :string
    add_column :enterprises, :linkedin, :string
  end
end
