# frozen_string_literal: true

module Admin
  class ProductsV3Reflex < ApplicationReflex

    def fetch
      cable_ready.replace(
        selector: "#products-content",
        html: render(partial: "admin/products_v3/content")
      ).broadcast

      morph :nothing
    end
  end
end
