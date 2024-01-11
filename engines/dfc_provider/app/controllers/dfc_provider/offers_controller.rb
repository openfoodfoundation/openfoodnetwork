# frozen_string_literal: true

module DfcProvider
  class OffersController < DfcProvider::ApplicationController
    before_action :check_enterprise

    def show
      subject = DfcBuilder.offer(variant)
      render json: DfcIo.export(subject)
    end

    private

    def variant
      @variant ||= current_enterprise.supplied_variants.find(params[:id])
    end
  end
end
