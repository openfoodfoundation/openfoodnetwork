# frozen_string_literal: true

require "tasks/sample_data/logging"

module SampleData
  class TaxonFactory
    include Logging

    def create_samples
      log "Creating taxonomies:"
      taxonomy = Spree::Taxonomy.find_or_create_by!(name: 'Products')
      taxons = ['Vegetables', 'Fruit', 'Oils', 'Preserves and Sauces', 'Dairy', 'Fungi']
      taxons.each do |taxon_name|
        create_taxon(taxonomy, taxon_name)
      end
    end

    private

    def create_taxon(taxonomy, taxon_name)
      return if Spree::Taxon.where(name: taxon_name).exists?

      log "- #{taxon_name}"
      Spree::Taxon.create!(
        name: taxon_name,
        parent_id: taxonomy.root.id,
        taxonomy_id: taxonomy.id
      )
    end
  end
end
