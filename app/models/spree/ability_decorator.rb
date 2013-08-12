
class AbilityDecorator
  include CanCan::Ability
  def initialize(user)
    if user.enterprises.count > 0

      #User can only access products that they are a supplier for
      can [:create], Spree::Product
      can [:admin, :read, :update, :bulk_edit, :clone, :destroy], Spree::Product  do |product|
        user.enterprises.include? product.supplier
      end

      can [:admin, :index, :read, :create, :edit], Spree::Variant
      can [:admin, :index, :read, :create, :edit], Spree::ProductProperty
      can [:admin, :index, :read, :create, :edit], Spree::Image

      can [:admin, :index, :read, :search], Spree::Taxon
      can [:admin, :index, :read, :create, :edit], Spree::Classification

      #User can only access orders that they are a distributor for
      can [:index, :create], Spree::Order
      can [:admin, :read, :update, :fire, :resend ], Spree::Order do |order|
        user.enterprises.include? order.distributor
      end

      can [:admin, :index, :read, :create, :edit, :update, :fire], Spree::Payment 
      can [:admin, :index, :read, :create, :edit, :update, :fire], Spree::Shipment
      can [:admin, :index, :read, :create, :edit, :update, :fire], Spree::Adjustment
      can [:admin, :index, :read, :create, :edit, :update, :fire], Spree::ReturnAuthorization

    end
  end
end

Spree::Ability.register_ability(AbilityDecorator)
