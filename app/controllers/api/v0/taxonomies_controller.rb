# frozen_string_literal: true

module Api
  module V0
    class TaxonomiesController < Api::V0::BaseController
      respond_to :json

      skip_authorization_check only: :jstree

      def jstree
        @taxonomy = Spree::Taxonomy.find(params[:id])
        render json: @taxonomy.root, serializer: Api::TaxonJstreeSerializer
      end
    end
  end
end
