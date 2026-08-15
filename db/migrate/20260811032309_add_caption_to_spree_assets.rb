# frozen_string_literal: true

class AddCaptionToSpreeAssets < ActiveRecord::Migration[7.2]
  def change
    add_column :spree_assets, :caption, :string
  end
end
