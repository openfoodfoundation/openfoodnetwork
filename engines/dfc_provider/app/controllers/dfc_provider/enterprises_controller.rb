# frozen_string_literal: true

# Controller used to provide the CatalogItem API for the DFC application
module DfcProvider
  class EnterprisesController < DfcProvider::ApplicationController
    before_action :check_enterprise, except: :index

    def index
      enterprises = current_user.enterprises.map do |enterprise|
        EnterpriseBuilder.enterprise(enterprise)
      end

      render json: DfcIo.export(
        *enterprises,
        *enterprises.map(&:mainContact),
        *enterprises.flat_map(&:localizations),
        *enterprises.flat_map(&:suppliedProducts),
        *enterprises.flat_map(&:catalogItems),
        *enterprises.flat_map(&:socialMedias),
      )
    end

    def show
      enterprise = EnterpriseBuilder.enterprise(current_enterprise)

      group_ids = current_enterprise.groups.map do |group|
        DfcProvider::Engine.routes.url_helpers.enterprise_group_url(group.id)
      end
      enterprise.registerSemanticProperty("dfc-b:affiliates") { group_ids }

      render json: DfcIo.export(
        enterprise,
        enterprise.mainContact,
        *enterprise.localizations,
        *enterprise.suppliedProducts,
        *enterprise.catalogItems,
        *enterprise.socialMedias,
      )
    end

    private

    def enterprise_id_param_name
      :id
    end
  end
end
