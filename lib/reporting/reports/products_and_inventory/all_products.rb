# frozen_string_literal: true

module Reporting
  module Reports
    module ProductsAndInventory
      class AllProducts < Base
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
              on_hand: proc{ |variant| variant.on_demand ? I18n.t(:on_demand) : variant.on_hand }
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
