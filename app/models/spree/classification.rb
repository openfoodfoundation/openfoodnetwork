# frozen_string_literal: true

module Spree
  class Classification < ApplicationRecord
    self.table_name = 'spree_products_taxons'
    belongs_to :product, class_name: "Spree::Product", touch: true
    belongs_to :taxon, class_name: "Spree::Taxon", touch: true

    before_destroy :dont_destroy_if_primary_taxon

    private

    def dont_destroy_if_primary_taxon
      return unless product.primary_taxon == taxon

      errors.add :base, I18n.t(:spree_classification_primary_taxon_error, taxon: taxon.name,
                                                                          product: product.name)
      throw :abort
    end
  end
end
