# frozen_string_literal: true

module Api
  module V0
    class TaxonsController < Api::V0::BaseController
      respond_to :json

      skip_authorization_check only: [:index, :show, :jstree]

      def index
        @taxons = if taxonomy
                    taxonomy.root.children
                  elsif params[:ids]
                    Spree::Taxon.where(id: raw_params[:ids].split(","))
                  else
                    Spree::Taxon.ransack(raw_params[:q]).result
                  end
        render json: @taxons, each_serializer: Api::TaxonSerializer
      end

      def jstree
        @taxon = taxon
        render json: @taxon.children, each_serializer: Api::TaxonJstreeSerializer
      end

      def create
        authorize! :create, Spree::Taxon
        @taxon = Spree::Taxon.new(taxon_params)
        @taxon.taxonomy_id = params[:taxonomy_id]
        taxonomy = Spree::Taxonomy.find_by(id: params[:taxonomy_id])

        if taxonomy.nil?
          @taxon.errors.add(:taxonomy_id, I18n.t(:invalid_taxonomy_id, scope: 'spree.api'))
          invalid_resource!(@taxon) && return
        end

        @taxon.parent_id = taxonomy.root.id unless params.dig(:taxon, :parent_id)

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
        render json: taxon, serializer: Api::TaxonSerializer, status: :no_content
      end

      private

      def taxonomy
        return if params[:taxonomy_id].blank?

        @taxonomy ||= Spree::Taxonomy.find(params[:taxonomy_id])
      end

      def taxon
        @taxon ||= taxonomy.taxons.find(params[:id])
      end

      def taxon_params
        return if params[:taxon].blank?

        params.require(:taxon).permit([:name, :parent_id, :position])
      end
    end
  end
end
