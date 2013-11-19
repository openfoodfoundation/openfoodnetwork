
class AbilityDecorator
  include CanCan::Ability
  def initialize(user)
    if user.enterprises.count > 0

      # Spree performs authorize! on (:create, nil) when creating a new order from admin, and also (:search, nil)
      # when searching for variants to add to the order
      can [:create, :search, :bulk_update], nil

      # Enterprise User can only access products that they are a supplier for
      can [:create], Spree::Product
      can [:admin, :read, :update, :product_distributions, :bulk_edit, :bulk_update, :clone, :destroy], Spree::Product  do |product|
        user.enterprises.include? product.supplier
      end

      can [:admin, :index, :read, :create, :edit, :update, :search], Spree::Variant
      can [:admin, :index, :read, :create, :edit], Spree::ProductProperty
      can [:admin, :index, :read, :create, :edit], Spree::Image

      can [:admin, :index, :read, :search], Spree::Taxon
      can [:admin, :index, :read, :create, :edit], Spree::Classification

      # Enterprise User can only access orders that they are a distributor for
      can [:index, :create], Spree::Order
      can [:admin, :read, :update, :fire, :resend], Spree::Order do |order|
        # We allow editing orders with a nil distributor as this state occurs
        # during the order creation process from the admin backend
        order.distributor.nil? || user.enterprises.include?(order.distributor)
      end
      can [:admin, :create], Spree::LineItem

      can [:admin, :index, :read, :create, :edit, :update, :fire], Spree::Payment
      can [:admin, :index, :read, :create, :edit, :update, :fire], Spree::Shipment
      can [:admin, :index, :read, :create, :edit, :update, :fire], Spree::Adjustment
      can [:admin, :index, :read, :create, :edit, :update, :fire], Spree::ReturnAuthorization

      # Enterprise User can only access payment methods for their distributors
      can [:index, :create], Spree::PaymentMethod
      can [:admin, :read, :update, :fire, :resend, :destroy], Spree::PaymentMethod do |payment_method|
        (user.enterprises & payment_method.distributors).any?
      end

      can [:index, :create], Spree::ShippingMethod
      can [:admin, :read, :update, :destroy], Spree::ShippingMethod do |shipping_method|
        (user.enterprises & shipping_method.distributors).any?
      end

      can [:create], OrderCycle
      can [:admin, :index, :read, :edit, :update, :bulk_update, :clone], OrderCycle do |order_cycle|
        user.enterprises.include? order_cycle.coordinator
      end

      can [:index, :create], EnterpriseFee
      can [:admin, :read, :edit, :bulk_update, :destroy], EnterpriseFee do |enterprise_fee|
        user.enterprises.include? enterprise_fee.enterprise
      end

      can [:admin, :index, :read, :create, :edit, :update], ExchangeVariant
      can [:admin, :index, :read, :create, :edit, :update], Exchange
      can [:admin, :index, :read, :create, :edit, :update], ExchangeFee

      can [:admin, :index, :create], Enterprise
      can [:read, :edit, :update, :bulk_update], Enterprise do |enterprise|
        user.enterprises.include? enterprise
      end

      # Enterprise User can access reports page
      can [:admin, :index, :orders_and_distributors, :group_buys, :bulk_coop, :payments, :orders_and_fulfillment, :products_and_inventory], :report
    end
  end
end

Spree::Ability.register_ability(AbilityDecorator)
