# frozen_string_literal: true

# Controller used to provide the Address API for the DFC application
module DfcProvider
  class AddressesController < DfcProvider::ApplicationController
    def show
      address = Spree::Address.find(params.require(:id))

      return not_found unless authorized(address)

      dfc_address = AddressBuilder.address(address)
      render json: DfcIo.export(dfc_address)
    end

    private

    # Does the current user have access to this address?
    #
    # It's possible to guess address ids and therefore we need to prevent the
    # collection of sensitive customer data.
    #
    # We may want to extend the list of authorised addresses once the DFC API
    # references them. To start with, we would only need enterprise addresses
    # but I included a few more options to show how this will probably evolve.
    #
    # Currently not checked models:
    #
    # - Spree::Card
    # - Spree::Order
    # - Spree::Shipment
    # - Subscription
    def authorized(address)
      user_address(address) ||
        [
          customer_address(address),
          public_enterprise_group_address(address),
          public_enterprise_address(address),
          managed_enterprise_address(address),
        ].any?(&:exists?)
    end

    def user_address(address)
      return false if current_user.is_a? ApiUser

      current_user.ship_address_id == address.id ||
        current_user.bill_address_id == address.id
    end

    def customer_address(address)
      current_user.customers.where(bill_address: address).or(
        current_user.customers.where(ship_address: address)
      )
    end

    def public_enterprise_group_address(address)
      EnterpriseGroup.where(address:)
    end

    def public_enterprise_address(address)
      Enterprise.activated.visible.is_distributor.where(address:)
    end

    def managed_enterprise_address(address)
      current_user.enterprises.where(address:)
    end
  end
end
