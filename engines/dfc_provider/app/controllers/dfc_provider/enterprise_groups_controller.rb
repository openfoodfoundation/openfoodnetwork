# frozen_string_literal: true

# OFN EnterpriseGroup is represented as DFC Enterprise.
module DfcProvider
  class EnterpriseGroupsController < DfcProvider::ApplicationController
    def index
      person = PersonBuilder.person(current_user)
      groups = current_user.owned_groups
      enterprises = groups.map do |group|
        EnterpriseBuilder.enterprise_group(group)
      end
      person.affiliatedOrganizations = enterprises
      render json: DfcIo.export(person, *enterprises)
    end

    def show
      group = EnterpriseGroup.find(params[:id])
      address = AddressBuilder.address(group.address)
      enterprise = EnterpriseBuilder.enterprise_group(group)
      enterprise.localizations = [address]
      render json: DfcIo.export(enterprise, address)
    end
  end
end
