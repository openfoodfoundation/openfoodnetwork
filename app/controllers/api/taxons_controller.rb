module Api
  class TaxonsController < Api::BaseController
    respond_to :json

    skip_authorization_check only: [:index, :show, :jstree]

    def index
      if taxonomy
        @taxons = taxonomy.root.children
      else
        if params[:ids]
          @taxons = Spree::Taxon.where(id: params[:ids].split(","))
        else
          @taxons = Spree::Taxon.ransack(params[:q]).result
        end
      end
      render json: @taxons, each_serializer: Api::TaxonSerializer
    end

    def show
      @taxon = taxon
      render json: @taxon, serializer: Api::TaxonSerializer
    end

    def jstree
      show
    end

    private

    def taxonomy
      return if params[:taxonomy_id].blank?
      @taxonomy ||= Spree::Taxonomy.find(params[:taxonomy_id])
    end

    def taxon
      @taxon ||= taxonomy.taxons.find(params[:id])
    end
  end
end
