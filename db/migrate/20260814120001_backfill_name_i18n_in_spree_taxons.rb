# frozen_string_literal: true

class BackfillNameI18nInSpreeTaxons < ActiveRecord::Migration[7.2]
  class Taxon < ApplicationRecord
    self.table_name = "spree_taxons"
  end

  def up
    locale = I18n.default_locale.to_s

    execute <<~SQL
      UPDATE spree_taxons
      SET name_i18n = jsonb_build_object(#{connection.quote(locale)}, name)
    SQL
  end

  def down
    Taxon.update_all(name_i18n: {})
  end
end
