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
      enterprise = EnterpriseBuilder.enterprise_group(group)
      render json: DfcIo.export(enterprise)
    end
  end
end
