# frozen_string_literal: true

module EnterprisesHelper
  def current_distributor
    @current_distributor ||= current_order(false)&.distributor
  end

  def current_customer
    return nil unless spree_current_user && current_distributor

    @current_customer ||= spree_current_user.customer_of(current_distributor)
  end

  def available_shipping_methods
    OrderAvailableShippingMethods.new(current_order, current_customer).to_a
  end

  def available_payment_methods
    OrderAvailablePaymentMethods.new(current_order, current_customer).to_a
  end

  def managed_enterprises
    Enterprise.managed_by(spree_current_user)
  end

  def editable_enterprises
    OpenFoodNetwork::Permissions.new(spree_current_user).
      editable_enterprises.
      order('is_primary_producer ASC, name')
  end

  def enterprises_options(enterprises)
    enterprises.map { |enterprise|
      [enterprise.name + ": " + enterprise.address.address1 + ", " + enterprise.address.city,
       enterprise.id.to_i]
    }
  end

  def enterprises_to_names(enterprises)
    enterprises.map(&:name).sort.join(', ')
  end

  def enterprise_type_name(enterprise)
    if enterprise.sells == 'none'
      enterprise.producer_profile_only ? I18n.t(:profile) : I18n.t(:supplier_only)
    else
      I18n.t(:has_shopfront)
    end
  end

  def enterprise_confirm_delete_message(enterprise)
    if enterprise.supplied_products.present?
      I18n.t(:enterprise_confirm_delete_message,
             product: pluralize(enterprise.supplied_products.count, 'product'))
    else
      t(:are_you_sure)
    end
  end

  # Copied and modified from Spree's link_to_delete, which does not
  # allow customisation of the confirm message
  def link_to_delete_enterprise(enterprise)
    url = object_url(enterprise)
    name = t(:delete)
    options = {}
    options[:class] = "delete-resource"
    options[:data] = { action: 'remove', confirm: enterprise_confirm_delete_message(enterprise) }
    link_to_with_icon 'icon-trash', name, url, options
  end

  def order_changes_allowed?
    current_order&.distributor&.allow_order_changes?
  end

  def show_bought_items?
    order_changes_allowed? && current_order.finalised_line_items.present?
  end

  def subscriptions_enabled?
    spree_current_user.admin? || spree_current_user.enterprises.where(enable_subscriptions: true).any?
  end

  def enterprise_url_selector(enterprise)
    if enterprise.is_distributor
      main_app.enterprise_shop_url(enterprise)
    else
      main_app.producers_url
    end
  end

  def hide_ofn_navigation?
    # if we are not on a shopfront, a cart page, checkout page or the order confirmation page
    # then we should show the OFN navigation
    # whatever the current distributor has set for the hide_ofn_navigation preference
    return false unless current_distributor && current_page?(main_app.enterprise_shop_path(current_distributor)) || # shopfront
                        request.path.start_with?(main_app.checkout_path) || # checkout
                        current_page?(main_app.cart_path) || # cart
                        request.path.start_with?("/orders/") # order confirmation

    distributor = if request.path.start_with?("/orders/")
                    # if we are on an order confirmation page,
                    # we need to get the distributor from the order, not the current one
                    Spree::Order.find_by(number: params[:id]).distributor
                  else
                    current_distributor
                  end

    # if the current distributor has the hide_ofn_navigation preference set to true
    # then we should hide the OFN navigation
    distributor.preferred_hide_ofn_navigation
  end
end
