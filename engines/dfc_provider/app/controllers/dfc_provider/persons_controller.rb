# frozen_string_literal: true

# Controller used to provide the Persons API for the DFC application
module DfcProvider
  class PersonsController < DfcProvider::ApplicationController
    before_action :check_user_accessibility

    def show
      person = PersonBuilder.person(user)
      render json: DfcIo.export(person)
    end

    def affiliate_sales_data
      render json: DfcIo.export(
        AffiliateSalesDataBuilder.build_person(user),
        *AffiliateSalesDataBuilder.build_orders,
        *AffiliateSalesDataBuilder.build_sales_session,
      )
    end

    private

    def user
      @user ||= Spree::User.find(params[:id])
    end

    def check_user_accessibility
      return if current_user == user

      not_found
    end
  end
end
