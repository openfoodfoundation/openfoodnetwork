module Spree
  module Api
    class TaxonsController < Spree::Api::BaseController
      respond_to :json

      def index
        if taxonomy
          @taxons = taxonomy.root.children
        else
          if params[:ids]
            @taxons = Taxon.where(id: params[:ids].split(","))
          else
            @taxons = Taxon.ransack(params[:q]).result
          end
        end
        respond_with(@taxons)
      end

      def show
        @taxon = taxon
        respond_with(@taxon)
      end

      def jstree
        show
      end

      private

      def taxonomy
        return if params[:taxonomy_id].blank?
        @taxonomy ||= Taxonomy.find(params[:taxonomy_id])
      end
    end
  end
end
