# frozen_string_literal: true

require 'open_food_network/available_payment_method_filter'

module EnterprisesHelper
  def current_distributor
    @current_distributor ||= current_order(false)&.distributor
  end

  def current_customer
    return nil unless spree_current_user && current_distributor

    @current_customer ||= spree_current_user.customer_of(current_distributor)
  end

  def available_shipping_methods
    return [] if current_distributor.blank?

    shipping_methods = current_distributor.shipping_methods.display_on_checkout.to_a

    applicator = OpenFoodNetwork::TagRuleApplicator.new(current_distributor,
                                                        "FilterShippingMethods", current_customer&.tag_list)
    applicator.filter!(shipping_methods)

    shipping_methods.uniq
  end

  def available_payment_methods
    return [] if current_distributor.blank?

    payment_methods = current_distributor.payment_methods.available(:front_end).to_a

    filter = OpenFoodNetwork::AvailablePaymentMethodFilter.new
    filter.filter!(payment_methods)

    applicator = OpenFoodNetwork::TagRuleApplicator.new(current_distributor,
                                                        "FilterPaymentMethods", current_customer&.tag_list)
    applicator.filter!(payment_methods)

    payment_methods
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
end
