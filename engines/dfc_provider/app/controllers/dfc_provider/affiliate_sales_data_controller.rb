# frozen_string_literal: true

module DfcProvider
  # Aggregates anonymised sales data for a research project.
  class AffiliateSalesDataController < DfcProvider::ApplicationController
    rescue_from Date::Error, with: -> { head :bad_request }

    def show
      person = AffiliateSalesDataBuilder.person(current_user, filter_params)

      render json: DfcIo.export(person)
    end

    private

    def filter_params
      {
        start_date: parse_date(params[:startDate]),
        end_date: parse_date(params[:endDate]),
      }
    end

    def parse_date(string)
      return if string.blank?

      Date.parse(string)
    end
  end
end
