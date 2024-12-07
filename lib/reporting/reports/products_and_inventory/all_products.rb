# frozen_string_literal: true

module Reporting
  module Reports
    module ProductsAndInventory
      class AllProducts < Base
        def default_params
          {
            fields_to_hide: [:tax_category]
          }
        end

        def message
          I18n.t("spree.admin.reports.products_and_inventory.all_products.message")
        end

        def custom_headers
          {
            on_demand: I18n.t("admin.on_demand?"),
            on_hand: I18n.t("admin.on_hand")
          }
        end

        def columns
          super.merge(
            {
              on_demand: proc{ |variant| variant.on_demand },
              on_hand: proc{ |variant| variant.on_demand ? I18n.t(:on_demand) : variant.on_hand },
              tax_category: proc { |variant| variant.tax_category_id && variant.tax_category.name }
            }
          )
        end

        def filter_on_hand(variants)
          variants # do not filter
        end
      end
    end
  end
end
