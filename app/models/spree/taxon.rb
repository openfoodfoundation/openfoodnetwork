# frozen_string_literal: true

module Spree
  class Taxon < ApplicationRecord
    has_many :variants, class_name: "Spree::Variant", foreign_key: "primary_taxon_id",
                        inverse_of: :primary_taxon, dependent: :restrict_with_error

    has_many :products, through: :variants, dependent: nil

    before_create :set_permalink

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

    def set_permalink
      self.permalink = UrlGenerator.to_url(name)
    end

    # For #2759
    def to_param
      permalink
    end

    # Find all the taxons of supplied products for each enterprise, indexed by enterprise.
    # Format: {enterprise_id => [taxon_id, ...]}
    def self.supplied_taxons
      taxons = {}

      Spree::Taxon.
        joins(variants: :supplier).
        select('spree_taxons.*, enterprises.id AS enterprise_id').
        each do |t|
          taxons[t.enterprise_id.to_i] ||= Set.new
          taxons[t.enterprise_id.to_i] << t.id
        end

      taxons
    end

    # Find all the taxons of distributed products for each enterprise, indexed by enterprise.
    # May return :all taxons (distributed in open and closed order cycles),
    # or :current taxons (distributed in an open order cycle).
    #
    # Format: {enterprise_id => [taxon_id, ...]}
    def self.distributed_taxons(which_taxons = :all)
      ents_and_vars = ExchangeVariant.joins(exchange: :order_cycle).merge(Exchange.outgoing)
        .select("DISTINCT variant_id, receiver_id AS enterprise_id")

      ents_and_vars = ents_and_vars.merge(OrderCycle.active) if which_taxons == :current

      taxons = Spree::Taxon
        .select("DISTINCT spree_taxons.id, ents_and_vars.enterprise_id")
        .joins(:variants)
        .joins("
          INNER JOIN (#{ents_and_vars.to_sql}) AS ents_and_vars
          ON spree_variants.id = ents_and_vars.variant_id")

      taxons.each_with_object({}) do |t, ts|
        ts[t.enterprise_id.to_i] ||= Set.new
        ts[t.enterprise_id.to_i] << t.id
      end
    end

    private

    def permalink_end
      return UrlGenerator.to_url(name) if permalink.blank?

      permalink.split('/').last
    end
  end
end
