# frozen_string_literal: true

class ProductsTableComponent < ViewComponentReflex::Component
  def initialize(user:)
    super
    @columns = [{ label: I18n.t("admin.products_page.columns_selector.price"), value: "price" },
                { label: I18n.t("admin.products_page.columns_selector.unit"), value: "unit" }]
    @selected = ["price", "unit"]
    @per_page = [{ label: "10", value: 10 }, { label: "25", value: 25 }, { label: "50", value: 50 },
                 { label: "100", value: 100 }]
    @per_page_selected = [10]
    @user = user

    fetch_products
  end

  def toggle_column
    column = element.dataset['value']
    @selected = @selected.include?(column) ? @selected - [column] : @selected + [column]
  end

  def toggle_per_page
    selected = element.dataset['value'].to_i
    @per_page_selected = [selected] if [10, 25, 50, 100].include?(selected)
    fetch_products
  end

  private

  def fetch_products
    @products = Spree::Product.managed_by(@user).order('name asc').limit(@per_page_selected.first)
  end
end
