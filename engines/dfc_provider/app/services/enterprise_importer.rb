# frozen_string_literal: true

class EnterpriseImporter
  def import(owner, dfc_enterprise)
    address = dfc_enterprise.localizations.first
    state = Spree::State.find_by(name: address.region) || Spree::State.first
    owner.owned_enterprises.create!(
      name: dfc_enterprise.name,
      address: Spree::Address.new(
        address1: address.street,
        city: address.city,
        zipcode: address.postalCode,
        state: state,
        country: state.country,
      ),
    )
  end
end
