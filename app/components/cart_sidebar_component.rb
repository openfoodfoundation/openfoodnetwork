# frozen_string_literal: true

# Server-rendered cart sidebar, replacing the AngularJS cart sidebar
# (app/views/shared/menu/_cart_sidebar.html.haml) when the turbo_cart
# feature is enabled. It is re-rendered via Turbo Streams on every cart
# change, so it must not be fragment cached.
class CartSidebarComponent < ViewComponent::Base
  MAX_NAME_LENGTH = 20

  def initialize(order:)
    @order = order
    super()
  end

  private

  attr_reader :order

  # The line items are already loaded and scoped to the distributor by
  # `current_order`, so we don't re-query them here.
  def line_items
    @line_items ||= order&.line_items || []
  end

  def total_item_count
    line_items.sum(&:quantity)
  end

  def variant_name(variant)
    name = if variant.product.name == variant.name_to_display
             variant.product.name
           else
             "#{variant.product.name} - #{variant.name_to_display}"
           end

    helpers.truncate(name, length: MAX_NAME_LENGTH)
  end

  def distributor
    order&.distributor
  end

  def shopping_path
    if distributor
      helpers.main_app.shop_path
    else
      helpers.main_app.shops_path
    end
  end

  # Same logic as ShopHelper#show_shopping_cta?, but based on the order's
  # distributor so the component doesn't depend on controller helpers.
  def show_shopping_cta?
    return false if helpers.current_page?(helpers.main_app.shops_path) && distributor.blank?

    return false if distributor.present? &&
                    helpers.current_page?(helpers.main_app.enterprise_shop_path(distributor))

    true
  end
end
