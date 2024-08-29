# frozen_string_literal: true

module DfcProvider
  # Aggregates anonymised sales data for a research project.
  class AffiliateSalesDataController < DfcProvider::ApplicationController
    def show
      person = AffiliateSalesDataBuilder.person(current_user)

      render json: DfcIo.export(person)
    end
  end
end
