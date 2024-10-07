# frozen_string_literal: true

require 'cancan'

module Spree
  class Ability
    include CanCan::Ability

    def initialize(user)
      clear_aliased_actions

      # override cancan default aliasing (we don't want to differentiate between read and index)
      alias_action :delete, to: :destroy
      alias_action :edit, to: :update
      alias_action :new, to: :create
      alias_action :new_action, to: :create
      alias_action :show, to: :read

      user ||= Spree::User.new

      if user.respond_to?(:has_spree_role?) && user.has_spree_role?('admin')
        can :manage, :all
      else
        can [:index, :read], Country
        can :create, Order
        can :read, Order do |order, token|
          order.user == user || (order.token && token == order.token)
        end
        can :update, Order do |order, token|
          order.user == user || (order.token && token == order.token)
        end
        can [:index, :read], ProductProperty
        can [:index, :read], Property
        can :create, Spree::User
        can [:read, :update, :destroy], Spree::User, id: user.id
        can [:index, :read], State
        can [:index, :read], StockItem
        can [:index, :read], StockMovement
        can [:index, :read], Taxon
        can [:index, :read], Variant
        can [:index, :read], Zone
      end

      add_shopping_abilities user
      add_base_abilities user if is_new_user? user
      add_enterprise_management_abilities user if can_manage_enterprises? user
      add_group_management_abilities user if can_manage_groups? user
      add_product_management_abilities user if can_manage_products? user
      add_order_cycle_management_abilities user if can_manage_order_cycles? user
      add_order_management_abilities user if can_manage_orders? user
      add_relationship_management_abilities user if can_manage_relationships? user
    end

    # New users have no enterprises.
    def is_new_user?(user)
      user.enterprises.blank?
    end

    # Users can manage an enterprise if they have one.
    def can_manage_enterprises?(user)
      user.enterprises.present?
    end

    # Users can manage a group if they have one.
    def can_manage_groups?(user)
      user.owned_groups.present?
    end

    # Users can manage products if they have an enterprise that is not a profile.
    def can_manage_products?(user)
      can_manage_enterprises?(user) &&
        user.enterprises.any? { |e| e.category != :hub_profile && e.producer_profile_only != true }
    end

    # Users can manage order cycles if they manage a sells own/any enterprise
    # OR if they manage a producer which is included in any order cycles
    def can_manage_order_cycles?(user)
      can_manage_orders?(user) ||
        OrderCycle.visible_by(user).any?
    end

    # Users can manage orders if they have a sells own/any enterprise.
    def can_manage_orders?(user)
      ( user.enterprises.map(&:sells) & %w(own any) ).any?
    end

    def can_manage_relationships?(user)
      can_manage_enterprises? user
    end

    def add_shopping_abilities(user)
      can [:destroy], Spree::LineItem do |item|
        user == item.order.user &&
          item.order.changes_allowed?
      end

      can [:cancel, :bulk_cancel], Spree::Order do |order|
        order.user == user
      end

      can [:update, :destroy], Spree::CreditCard do |credit_card|
        credit_card.user == user
      end

      can [:update], Customer do |customer|
        customer.user == user
      end
    end

    # New users can create an enterprise, and gain other permissions from doing this.
    def add_base_abilities(_user)
      can [:create], Enterprise
    end

    def add_group_management_abilities(user)
      can [:admin, :index], :overview
      can [:admin, :index], EnterpriseGroup
      can [:read, :edit, :update], EnterpriseGroup do |group|
        user.owned_groups.include? group
      end
    end

    def add_enterprise_management_abilities(user)
      # We perform authorize! on (:create, nil) when creating a new order from admin,
      #   and also (:search, nil) when searching for variants to add to the order
      can [:create, :search], nil

      can [:admin, :index], :overview

      can [:admin, :index, :read, :create, :edit, :update_positions, :destroy], ProducerProperty

      can [:admin, :map_by_tag, :destroy], TagRule do |tag_rule|
        user.enterprises.include? tag_rule.enterprise
      end

      can [:admin, :index, :create], Enterprise
      can [:read, :edit, :update,
           :remove_logo, :remove_promo_image, :remove_terms_and_conditions,
           :bulk_update, :resend_confirmation], Enterprise do |enterprise|
        OpenFoodNetwork::Permissions.new(user).editable_enterprises.include? enterprise
      end
      can [:welcome, :register], Enterprise do |enterprise|
        enterprise.owner == user
      end
      can [:manage_payment_methods,
           :manage_shipping_methods,
           :manage_enterprise_fees,
           :manage_connected_apps], Enterprise do |enterprise|
        user.enterprises.include? enterprise
      end

      # All enterprises can have fees, though possibly suppliers don't need them?
      can [:index, :create], EnterpriseFee
      can [:admin, :read, :edit, :bulk_update, :destroy], EnterpriseFee do |enterprise_fee|
        user.enterprises.include? enterprise_fee.enterprise
      end

      can [:admin, :known_users, :customers], :search

      can [:admin, :show], :account

      # For printing own account invoice orders
      can [:print], Spree::Order do |order|
        order.user == user
      end

      can [:admin, :bulk_update], ColumnPreference do |column_preference|
        column_preference.user == user
      end

      can [:admin, :connect, :status, :destroy], StripeAccount do |stripe_account|
        user.enterprises.include? stripe_account.enterprise
      end

      can [:admin, :create], :manager_invitation

      can [:admin, :index, :destroy], :oidc_setting

      can [:admin, :create], Voucher
    end

    def add_product_management_abilities(user)
      # Enterprise User can only access products that they are a supplier for
      can [:create], Spree::Product
      can [:admin, :read, :index, :update,
           :seo, :group_buy_options,
           :bulk_update, :clone, :delete,
           :destroy], Spree::Product do |product|
        OpenFoodNetwork::Permissions.new(user).managed_product_enterprises.include?(
          product.variants.first.supplier
        )
      end

      can [:admin, :index, :bulk_update, :destroy, :destroy_variant, :clone], :products_v3

      can [:create], Spree::Variant
      can [:admin, :index, :read, :edit,
           :update, :search, :delete, :destroy], Spree::Variant do |variant|
        OpenFoodNetwork::Permissions.new(user).
          managed_product_enterprises.include? variant.supplier
      end

      can [:admin, :index, :read, :update, :bulk_update, :bulk_reset], VariantOverride do |vo|
        next false unless vo.hub.present? && vo.variant&.supplier.present?

        hub_auth = OpenFoodNetwork::Permissions.new(user).
          variant_override_hubs.
          include? vo.hub

        producer_auth = OpenFoodNetwork::Permissions.new(user).
          variant_override_producers.
          include? vo.variant.supplier

        hub_auth && producer_auth
      end

      can [:admin, :create, :update], InventoryItem do |ii|
        next false unless ii.enterprise.present? &&
                          ii.variant&.supplier.present?

        hub_auth = OpenFoodNetwork::Permissions.new(user).
          variant_override_hubs.
          include? ii.enterprise

        producer_auth = OpenFoodNetwork::Permissions.new(user).
          variant_override_producers.
          include? ii.variant.supplier

        hub_auth && producer_auth
      end

      can [:admin, :index, :read, :create,
           :edit, :update_positions, :destroy], Spree::ProductProperty
      can [:admin, :index, :read, :create, :edit, :update, :destroy], Spree::Image

      can [:admin, :index, :read, :search], Spree::Taxon

      can [:admin, :index, :guide, :import, :save, :save_data,
           :validate_data, :reset_absent_products], ProductImport::ProductImporter

      can [:admin, :index], ::Admin::DfcProductImportsController

      # Reports page
      can [:admin, :index, :show, :create], ::Admin::ReportsController
      can [:admin, :show, :create, :customers, :orders_and_distributors, :group_buys, :payments,
           :orders_and_fulfillment, :products_and_inventory, :order_cycle_management,
           :packing, :enterprise_fee_summary, :bulk_coop, :suppliers], :report
    end

    def add_order_cycle_management_abilities(user)
      can [
        :admin, :index, :read, :edit, :update, :incoming, :outgoing, :checkout_options
      ], OrderCycle do |order_cycle|
        OrderCycle.visible_by(user).include? order_cycle
      end
      can [:admin, :index, :create], Schedule
      can [:admin, :update, :destroy], Schedule do |schedule|
        OpenFoodNetwork::Permissions.new(user).editable_schedules.include? schedule
      end
      can [:bulk_update, :clone, :destroy, :notify_producers], OrderCycle do |order_cycle|
        user.enterprises.include? order_cycle.coordinator
      end
      can [:for_order_cycle], Enterprise
      can [:for_order_cycle], EnterpriseFee
    end

    def add_order_management_abilities(user)
      can [:index, :create], Spree::Order
      can [:read, :update, :fire, :resend, :invoice, :print], Spree::Order do |order|
        # We allow editing orders with a nil distributor as this state occurs
        # during the order creation process from the admin backend
        order.distributor.nil? ||
          # Enterprise User can access orders that they are a distributor for
          user.enterprises.include?(order.distributor) ||
          # Enterprise User can access orders that are placed inside a OC they coordinate
          order.order_cycle&.coordinated_by?(user)
      end
      can [:admin, :bulk_management, :managed, :distribution], Spree::Order do
        user.admin? || user.enterprises.any?(&:is_distributor)
      end
      can [:admin, :index, :create, :show, :poll, :generate], :invoice
      can [:admin, :visible], Enterprise
      can [:admin, :index, :create, :update, :destroy], :line_item
      can [:admin, :index, :create], Spree::LineItem
      can [:destroy, :update], Spree::LineItem do |item|
        order = item.order
        user.admin? ||
          user.enterprises.include?(order.distributor) ||
          order.order_cycle&.coordinated_by?(user)
      end

      can [:admin, :index, :read, :create, :edit, :update, :fire], Spree::Payment
      can [:admin, :index, :read, :create, :edit, :update, :fire], Spree::Shipment
      can [:admin, :index, :read, :create, :edit, :update, :fire], Spree::Adjustment
      can [:admin, :index, :read, :create, :edit, :update, :fire], Spree::ReturnAuthorization
      can [:destroy], Spree::Adjustment do |adjustment|
        if user.admin?
          true
        else
          order = adjustment.order
          user.enterprises.include?(order.distributor) ||
            order.order_cycle&.coordinated_by?(user)
        end
      end

      can [:create], OrderCycle

      can [:admin, :index, :read, :create, :edit, :update], ExchangeVariant
      can [:admin, :index, :read, :create, :edit, :update], Exchange
      can [:admin, :index, :read, :create, :edit, :update], ExchangeFee

      # Enterprise user can only access payment and shipping methods for their distributors
      can [:index, :create], Spree::PaymentMethod
      can [:admin, :read, :update, :fire, :resend,
           :destroy, :show_provider_preferences], Spree::PaymentMethod do |payment_method|
        (user.enterprises & payment_method.distributors).any?
      end

      can [:index, :create], Spree::ShippingMethod
      can [:admin, :read, :update, :destroy], Spree::ShippingMethod do |shipping_method|
        (user.enterprises & shipping_method.distributors).any?
      end

      # Reports page
      can [:admin, :index, :show, :create], ::Admin::ReportsController
      can [:admin, :customers, :group_buys, :sales_tax, :payments,
           :orders_and_distributors, :orders_and_fulfillment, :products_and_inventory,
           :order_cycle_management, :xero_invoices, :enterprise_fee_summary, :bulk_coop], :report

      can [:create], Customer
      can [:admin, :index, :update,
           :destroy, :show], Customer, enterprise_id: Enterprise.managed_by(user).pluck(:id)
      can [:admin, :new, :index], Subscription
      can [:create, :edit, :update, :cancel, :pause, :unpause], Subscription do |subscription|
        user.enterprises.include?(subscription.shop)
      end
      can [:admin, :build], SubscriptionLineItem
      can [:destroy], SubscriptionLineItem do |subscription_line_item|
        user.enterprises.include?(subscription_line_item.subscription.shop)
      end
      can [:admin, :edit, :cancel, :resume], ProxyOrder do |proxy_order|
        user.enterprises.include?(proxy_order.subscription.shop)
      end
    end

    def add_relationship_management_abilities(user)
      can [:admin, :index, :create], EnterpriseRelationship
      can [:destroy], EnterpriseRelationship do |enterprise_relationship|
        user.enterprises.include?(enterprise_relationship.parent) ||
          user.enterprises.include?(enterprise_relationship.child)
      end
    end
  end
end
