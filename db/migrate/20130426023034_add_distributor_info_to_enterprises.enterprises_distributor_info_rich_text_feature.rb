# This migration comes from enterprises_distributor_info_rich_text_feature (originally 20130426022945)
class AddDistributorInfoToEnterprises < ActiveRecord::Migration
  def change
    add_column :enterprises, :distributor_info, :text
  end
end
