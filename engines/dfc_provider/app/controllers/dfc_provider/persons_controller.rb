# frozen_string_literal: true

# Controller used to provide the Persons API for the DFC application
module DfcProvider
  class PersonsController < DfcProvider::BaseController
    before_action :check_user_accessibility

    def show
      person = PersonBuilder.person(user)
      render json: DfcIo.export(person)
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
