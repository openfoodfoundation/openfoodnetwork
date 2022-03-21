# frozen_string_literal: true

class ProductsTableComponent < ViewComponentReflex::Component
  def initialize(user:)
    super
    @columns = [{ label: I18n.t("admin.products_page.columns_selector.price"), value: "price" },
                { label: I18n.t("admin.products_page.columns_selector.unit"), value: "unit" }]
    @selected = ["price", "unit"]
    @user = user

    fetch_products
  end

  def toggle_column
    column = element.dataset['value']
    @selected = @selected.include?(column) ? @selected - [column] : @selected + [column]
  end
  private

  def fetch_products
    @products = Spree::Product.managed_by(@user).order('name asc').limit(@per_page_selected.first)
  end
end
