# frozen_string_literal: true

class BackfillNameI18nInSpreeTaxons < ActiveRecord::Migration[7.2]
  class Taxon < ApplicationRecord
    self.table_name = "spree_taxons"
  end

  def up
    Taxon.find_each do |taxon|
      taxon.update_column(:name_i18n, { I18n.default_locale.to_s => taxon.name })
    end
  end

  def down
    Taxon.update_all(name_i18n: {})
  end
end
