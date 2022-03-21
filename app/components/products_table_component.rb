# frozen_string_literal: true

class ProductsTableComponent < ViewComponentReflex::Component
  def initialize(user:)
    super
    @columns = ["price", "unit"]
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
