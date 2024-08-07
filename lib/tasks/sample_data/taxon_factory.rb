# frozen_string_literal: true

require "tasks/sample_data/logging"

module SampleData
  class TaxonFactory
    include Logging

    def create_samples
      log "Creating taxonomies:"
      taxons = ['Vegetables', 'Fruit', 'Oils', 'Preserves and Sauces', 'Dairy', 'Fungi']
      taxons.each do |taxon_name|
        create_taxon(taxon_name)
      end
    end

    private

    def create_taxon(taxon_name)
      return if Spree::Taxon.where(name: taxon_name).exists?

      log "- #{taxon_name}"
      Spree::Taxon.create!(
        name: taxon_name
      )
    end
  end
end
