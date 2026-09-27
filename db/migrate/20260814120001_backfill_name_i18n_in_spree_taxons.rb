# frozen_string_literal: true

class BackfillNameI18nInSpreeTaxons < ActiveRecord::Migration[7.2]
  # Use a migration-local model to avoid coupling to application code that may
  # change over time (the app Taxon class will gain i18n behaviour that this
  # backfill doesn't need and that could break in future refactors).
  class Taxon < ActiveRecord::Base
    self.table_name = "spree_taxons"
  end

  def up
    locale = I18n.default_locale.to_s

    execute <<~SQL.squish
      UPDATE spree_taxons
      SET name_i18n = jsonb_build_object(#{connection.quote(locale)}, name)
    SQL
  end

  def down
    Taxon.update_all(name_i18n: {})
  end
end
