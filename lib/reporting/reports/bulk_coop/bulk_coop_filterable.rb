# frozen_string_literal: true

module Reporting
  module Reports
    module BulkCoop
      # Shared bulk co-op filtering, gated behind the :bulk_coop_filters feature
      # toggle. Included by the bulk co-op reports so the toggle check and the
      # group-buy variant lookup live in one place.
      module BulkCoopFilterable
        private

        def bulk_coop_filters_enabled?
          OpenFoodNetwork::FeatureToggle.enabled?(:bulk_coop_filters, *@user.enterprises)
        end

        def group_buy_variants
          Spree::Variant.joins(:product).where(spree_products: { group_buy: true })
        end

        # Keeps only the line items belonging to bulk (group-buy) variants.
        def bulk_coop_filter(items)
          return items unless bulk_coop_filters_enabled?

          items.where(variant: group_buy_variants)
        end
      end
    end
  end
end
