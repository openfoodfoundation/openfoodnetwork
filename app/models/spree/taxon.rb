# frozen_string_literal: true

module Spree
  class Taxon < ApplicationRecord
    has_many :variants, class_name: "Spree::Variant", foreign_key: "primary_taxon_id",
                        inverse_of: :primary_taxon, dependent: :restrict_with_error

    has_many :products, through: :variants, dependent: nil

    validates :name, presence: true

    # Indicate which filters should be used for this taxon
    def applicable_filters
      []
    end

    # Return meta_title if set otherwise generates from root name and/or taxon name
    def seo_title
      if meta_title
        meta_title
      else
        root? ? name : "#{root.name} - #{name}"
      end
    end

    # Find all the taxons of supplied products for each enterprise, indexed by enterprise.
    # Format: {enterprise_id => [taxon_id, ...]}
    #
    # Optionally, specify some enterprise_ids to scope the results
    def self.supplied_taxons(enterprise_ids = nil)
      taxons = Spree::Taxon.joins(variants: :supplier)

      taxons = taxons.where(enterprises: { id: enterprise_ids }) if enterprise_ids.present?

      taxons
        .pluck('spree_taxons.id, enterprises.id AS enterprise_id')
        .each_with_object({}) do |(taxon_id, enterprise_id), collection|
        collection[enterprise_id.to_i] ||= Set.new
        collection[enterprise_id.to_i] << taxon_id
      end
    end

    # Find all the taxons of distributed products for each enterprise, indexed by enterprise.
    # May return :all taxons (distributed in open and closed order cycles),
    # or :current taxons (distributed in an open order cycle).
    #
    # Format: {enterprise_id => [taxon_id, ...]}
    #
    # Optionally, specify some enterprise_ids to scope the results
    def self.distributed_taxons(which_taxons = :all, enterprise_ids = nil)
      ents_and_vars = ExchangeVariant.joins(exchange: :order_cycle).merge(Exchange.outgoing)
        .select("DISTINCT variant_id, receiver_id AS enterprise_id")

      ents_and_vars = ents_and_vars.merge(OrderCycle.active) if which_taxons == :current

      taxons = Spree::Taxon
        .select("DISTINCT spree_taxons.id, ents_and_vars.enterprise_id")
        .joins(:variants)
        .joins("
          INNER JOIN (#{ents_and_vars.to_sql}) AS ents_and_vars
          ON spree_variants.id = ents_and_vars.variant_id")

      if enterprise_ids.present?
        taxons = taxons.where(ents_and_vars: { enterprise_id: enterprise_ids })
      end

      taxons.each_with_object({}) do |t, ts|
        ts[t.enterprise_id.to_i] ||= Set.new
        ts[t.enterprise_id.to_i] << t.id
      end
    end
  end
end
