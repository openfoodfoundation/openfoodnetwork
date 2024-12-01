module Spree::Admin::TaxCategoriesHelper
  def tax_category_dropdown_options(require_tax_category)
    {
      :include_blank => Spree::Config.products_require_tax_category ? false : t(:none), 
      selected: Spree::Config.products_require_tax_category ? Spree::TaxCategory.find_by(is_default: true)&.id : nil
    }
  end
end