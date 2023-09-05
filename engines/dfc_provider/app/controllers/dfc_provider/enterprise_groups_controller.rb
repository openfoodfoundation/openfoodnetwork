# frozen_string_literal: true

# OFN EnterpriseGroup is represented as DFC Enterprise.
module DfcProvider
  class EnterpriseGroupsController < DfcProvider::ApplicationController
    def show
      group = EnterpriseGroup.find(params[:id])
      enterprise = EnterpriseBuilder.enterprise_group(group)
      render json: DfcIo.export(enterprise)
    end
  end
end
