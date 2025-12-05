# frozen_string_literal: true

class EnterpriseImporter
  def initialize(owner, dfc_enterprise)
    @owner = owner
    @dfc_enterprise = dfc_enterprise
  end

  def import
    enterprise = find || new

    apply(enterprise)

    enterprise
  end

  def find
    semantic_id = @dfc_enterprise.semanticId

    @owner.owned_enterprises.includes(:semantic_link)
      .find_by(semantic_link: { semantic_id: })
  end

  def new
    @owner.owned_enterprises.new(
      address: Spree::Address.new,
      semantic_link: SemanticLink.new(semantic_id: @dfc_enterprise.semanticId),
    )
  end

  def apply(enterprise)
    address = @dfc_enterprise.localizations.first
    state = Spree::State.find_by(name: address.region) || Spree::State.first

    enterprise.name = @dfc_enterprise.name
    enterprise.address.assign_attributes(
      address1: address.street,
      city: address.city,
      zipcode: address.postalCode,
      state: state,
      country: state.country,
    )
  end
end
