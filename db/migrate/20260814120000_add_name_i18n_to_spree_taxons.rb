# frozen_string_literal: true

class AddNameI18nToSpreeTaxons < ActiveRecord::Migration[7.2]
  def change
    add_column :spree_taxons, :name_i18n, :jsonb, null: false, default: {}
  end
end
