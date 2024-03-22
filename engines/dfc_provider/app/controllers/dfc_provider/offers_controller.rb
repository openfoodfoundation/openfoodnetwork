# frozen_string_literal: true

module DfcProvider
  class OffersController < DfcProvider::ApplicationController
    before_action :check_enterprise

    def show
      subject = OfferBuilder.build(variant)
      render json: DfcIo.export(subject)
    end

    def update
      offer = import

      return head :bad_request unless offer

      OfferBuilder.apply(offer, variant)

      variant.save!
    end

    private

    def variant
      @variant ||= current_enterprise.supplied_variants.find(params[:id])
    end
  end
end
