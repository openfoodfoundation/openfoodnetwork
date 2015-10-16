require 'open_food_network/products_and_inventory_report_base'

module OpenFoodNetwork
  class ProductsAndInventoryReport < ProductsAndInventoryReportBase
    def header
      [
        "Supplier",
        "Producer Suburb",
        "Product",
        "Product Properties",
        "Taxons",
        "Variant Value",
        "Price",
        "Group Buy Unit Quantity",
        "Amount"
      ]
    end

    def table
      variants.map do |variant|
        [
          variant.product.supplier.name,
          variant.product.supplier.address.city,
          variant.product.name,
          variant.product.properties.map(&:name).join(", "),
          variant.product.taxons.map(&:name).join(", "),
          variant.full_name,
          variant.price,
          variant.product.group_buy_unit_size,
          ""
        ]
      end
    end

  end
end
