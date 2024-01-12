# frozen_string_literal: true

module DfcProvider
  module EnterpriseGroups
    class AffiliatedByController < DfcProvider::ApplicationController
      def create
        group = EnterpriseGroup.find(params[:enterprise_group_id])

        authorize! :update, group

        enterprise_uri = RDF::URI.new(params[:@id])

        return head :bad_request unless enterprise_uri.valid?

        enterprise_id = ofn_id_from_uri(enterprise_uri)
        enterprise = Enterprise.find(enterprise_id)

        group.enterprises << enterprise

        head :created
      end

      def destroy
        group = EnterpriseGroup.find(params[:enterprise_group_id])

        authorize! :update, group

        group.enterprises.delete(params[:id])
      end

      private

      def ofn_id_from_uri(uri)
        # enterprise uri follow this format http://test.host/api/dfc/enterprises/{ofn_enterprise_id}
        uri.path.split("/").last
      end
    end
  end
end
