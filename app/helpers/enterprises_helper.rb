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
    Orders::AvailableShippingMethodsService.new(current_order, current_customer).to_a
  end

  def available_payment_methods
    Orders::AvailablePaymentMethodsService.new(current_order, current_customer).to_a
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
      ["#{enterprise.name}: #{enterprise.address.address1}, #{enterprise.address.city}",
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
    url = "#{object_url(enterprise)}?index=#{enterprise.id}"
    name = t(:delete)
    options = {}
    options[:data] = {
      turbo: true,
      'turbo-method': 'delete',
      'turbo-confirm': enterprise_confirm_delete_message(enterprise)
    }
    link_to_with_icon 'icon-trash', name, url, options
  end

  def order_changes_allowed?
    current_order&.distributor&.allow_order_changes?
  end

  def show_bought_items?
    order_changes_allowed? && current_order.finalised_line_items.present?
  end

  def subscriptions_enabled?
    spree_current_user.admin? ||
      spree_current_user.enterprises.where(enable_subscriptions: true).any?
  end

  def enterprise_url_selector(enterprise)
    if enterprise.is_distributor
      main_app.enterprise_shop_url(enterprise)
    else
      main_app.producers_url
    end
  end

  def main_logo_link(enterprise)
    return enterprise.white_label_logo_link if enterprise&.white_label_logo_link.present?

    main_app.root_path
  end
end
