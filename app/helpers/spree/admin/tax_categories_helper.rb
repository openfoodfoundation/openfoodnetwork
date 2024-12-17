# frozen_string_literal: true

module Spree
  module Admin
    module TaxCategoriesHelper
      def tax_category_dropdown_options(require_tax_category)
        if require_tax_category
          {
            include_blank: false,
            selected: Spree::TaxCategory.find_by(is_default: true)&.id
          }
        else
          {
            include_blank: t(:none),
          }
        end
      end
    end
  end
end
