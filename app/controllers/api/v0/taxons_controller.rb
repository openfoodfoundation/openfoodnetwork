# frozen_string_literal: true

module Api
  module V0
    class TaxonsController < Api::V0::BaseController
      respond_to :json

      skip_authorization_check only: [:index, :show]

      def index
        @taxons = if params[:ids]
                    Spree::Taxon.where(id: raw_params[:ids].split(","))
                  else
                    Spree::Taxon.ransack(raw_params[:q]).result
                  end
        render json: @taxons, each_serializer: Api::TaxonSerializer
      end

      def create
        authorize! :create, Spree::Taxon
        @taxon = Spree::Taxon.new(taxon_params)

        if @taxon.save
          render json: @taxon, serializer: Api::TaxonSerializer, status: :created
        else
          invalid_resource!(@taxon)
        end
      end

      def update
        authorize! :update, Spree::Taxon
        if taxon.update(taxon_params)
          render json: taxon, serializer: Api::TaxonSerializer, status: :ok
        else
          invalid_resource!(taxon)
        end
      end

      def destroy
        authorize! :delete, Spree::Taxon
        taxon.destroy
        head :no_content
      end

      private

      def taxon
        @taxon = Spree::Taxon.find(params[:id])
      end

      def taxon_params
        return if params[:taxon].blank?

        params.require(:taxon).permit([:name, :position])
      end
    end
  end
end
