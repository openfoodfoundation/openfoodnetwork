module Api
  class TaxonomiesController < Api::BaseController
    respond_to :json

    skip_authorization_check only: :jstree

    def jstree
      @taxonomy = Spree::Taxonomy.find(params[:id])
      render json: @taxonomy.root, serializer: Api::TaxonJstreeSerializer
    end
  end
end
