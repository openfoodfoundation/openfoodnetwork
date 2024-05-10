# frozen_string_literal: true

class RemoveDistributorInfoFromEnterprises < ActiveRecord::Migration[7.0]
  def change
    remove_column :enterprises, :distributor_info, :text
  end
end
