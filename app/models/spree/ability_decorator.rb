
class AbilityDecorator
  include CanCan::Ability
  def initialize(user)
    if user.enterprises.count > 0
      can [:admin, :read, :update, :bulk_edit], Spree::Product  do |product|
        user.enterprises.include? product.supplier
      end

      can [:create], Spree::Product
      can [:admin, :index, :read, :create, :edit], Spree::Variant
      can [:admin, :index, :read, :create, :edit], Spree::ProductProperty
      can [:admin, :index, :read, :create, :edit], Spree::Image

      can [:admin, :index, :read, :search], Spree::Taxon
      can [:admin, :index, :read, :create, :edit], Spree::Classification

      can [:admin, :index, :read], Spree::Order
    end
  end
end

Spree::Ability.register_ability(AbilityDecorator)
