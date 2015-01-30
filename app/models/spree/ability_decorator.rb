class AbilityDecorator
  include CanCan::Ability

  # All abilites are allocated from this initialiser, currently in 5 chunks.
  # Spree also defines other abilities.
  def initialize(user)
    add_base_abilities user if is_new_user? user
    add_enterprise_management_abilities user if can_manage_enterprises? user
    add_product_management_abilities user if can_manage_products? user
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

  # Users can manage products if they have an enterprise that is not a profile.
  def can_manage_products?(user)
    can_manage_enterprises?(user) &&
    user.enterprises.any? { |e| e.category != :hub_profile && e.producer_profile_only != true }
  end

  # Users can manage orders if they have a sells own/any enterprise.
  def can_manage_orders?(user)
    ( user.enterprises.map(&:sells) & %w(own any) ).any?
  end

  def can_manage_relationships?(user)
    can_manage_enterprises? user
  end

  # New users can create an enterprise, and gain other permissions from doing this.
  def add_base_abilities(user)
    can [:create], Enterprise
  end

  def add_enterprise_management_abilities(user)
    # Spree performs authorize! on (:create, nil) when creating a new order from admin, and also (:search, nil)
    # when searching for variants to add to the order
    can [:create, :search, :bulk_update], nil

    can [:admin, :index], :overview

    can [:admin, :index, :read, :create, :edit, :update_positions, :destroy], ProducerProperty

    can [:admin, :index, :create], Enterprise
    can [:read, :edit, :update, :bulk_update, :set_sells, :resend_confirmation], Enterprise do |enterprise|
      OpenFoodNetwork::Permissions.new(user).editable_enterprises.include? enterprise
    end
    can [:manage_payment_methods, :manage_shipping_methods, :manage_enterprise_fees], Enterprise do |enterprise|
      user.enterprises.include? enterprise
    end

    # All enterprises can have fees, though possibly suppliers don't need them?
    can [:index, :create], EnterpriseFee
    can [:admin, :read, :edit, :bulk_update, :destroy], EnterpriseFee do |enterprise_fee|
      user.enterprises.include? enterprise_fee.enterprise
    end

    can [:admin, :known_users], :search
  end

  def add_product_management_abilities(user)
    # Enterprise User can only access products that they are a supplier for
    can [:create], Spree::Product
    can [:admin, :read, :update, :product_distributions, :bulk_edit, :bulk_update, :clone, :destroy], Spree::Product do |product|
      OpenFoodNetwork::Permissions.new(user).managed_product_enterprises.include? product.supplier
    end

    can [:create], Spree::Variant
    can [:admin, :index, :read, :edit, :update, :search, :destroy], Spree::Variant do |variant|
      OpenFoodNetwork::Permissions.new(user).managed_product_enterprises.include? variant.product.supplier
    end

    can [:admin, :index, :read, :update, :bulk_update], VariantOverride do |vo|
      hub_auth = OpenFoodNetwork::Permissions.new(user).
        order_cycle_enterprises.is_distributor.
        include? vo.hub

      producer_auth = OpenFoodNetwork::Permissions.new(user).
        variant_override_producers.
        include? vo.variant.product.supplier

      hub_auth && producer_auth
    end

    can [:admin, :index, :read, :create, :edit, :update_positions, :destroy], Spree::ProductProperty
    can [:admin, :index, :read, :create, :edit, :update, :destroy], Spree::Image

    can [:admin, :index, :read, :search], Spree::Taxon
    can [:admin, :index, :read, :create, :edit], Spree::Classification

    # Reports page
    can [:admin, :index, :customers, :orders_and_distributors, :group_buys, :bulk_coop, :payments, :orders_and_fulfillment, :products_and_inventory], :report
  end

  def add_order_management_abilities(user)
    # Enterprise User can only access orders that they are a distributor for
    can [:index, :create], Spree::Order
    can [:read, :update, :fire, :resend], Spree::Order do |order|
      # We allow editing orders with a nil distributor as this state occurs
      # during the order creation process from the admin backend
      order.distributor.nil? || user.enterprises.include?(order.distributor)
    end
    can [:admin, :bulk_management], Spree::Order if user.admin? || user.enterprises.any?(&:is_distributor)
    can [:admin, :create], Spree::LineItem

    can [:admin, :index, :read, :create, :edit, :update, :fire], Spree::Payment
    can [:admin, :index, :read, :create, :edit, :update, :fire], Spree::Shipment
    can [:admin, :index, :read, :create, :edit, :update, :fire], Spree::Adjustment
    can [:admin, :index, :read, :create, :edit, :update, :fire], Spree::ReturnAuthorization

    can [:create], OrderCycle
    can [:admin, :index, :read, :edit, :update, :bulk_update, :clone], OrderCycle do |order_cycle|
      user.enterprises.include? order_cycle.coordinator
    end
    can [:for_order_cycle], Enterprise

    can [:admin, :index, :read, :create, :edit, :update], ExchangeVariant
    can [:admin, :index, :read, :create, :edit, :update], Exchange
    can [:admin, :index, :read, :create, :edit, :update], ExchangeFee

    # Enterprise user can only access payment and shipping methods for their distributors
    can [:index, :create], Spree::PaymentMethod
    can [:admin, :read, :update, :fire, :resend, :destroy, :show_provider_preferences], Spree::PaymentMethod do |payment_method|
      (user.enterprises & payment_method.distributors).any?
    end

    can [:index, :create], Spree::ShippingMethod
    can [:admin, :read, :update, :destroy], Spree::ShippingMethod do |shipping_method|
      (user.enterprises & shipping_method.distributors).any?
    end

    # Reports page
    can [:admin, :index, :customers, :orders_and_distributors, :group_buys, :bulk_coop, :payments, :orders_and_fulfillment, :products_and_inventory, :order_cycle_management], :report
  end


  def add_relationship_management_abilities(user)
    can [:admin, :index, :create], EnterpriseRelationship
    can [:destroy], EnterpriseRelationship do |enterprise_relationship|
      user.enterprises.include? enterprise_relationship.parent
    end
  end
end

Spree::Ability.register_ability(AbilityDecorator)
