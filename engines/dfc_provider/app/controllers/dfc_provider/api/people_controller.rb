# frozen_string_literal: true

# Controller used to provide the People API for the DFC application
module DfcProvider
  module Api
    class PeopleController < BaseController
      skip_before_filter :check_enterprise

      before_filter :find_user, :check_user_accessibility

      def show
        render json: @user, serializer: DfcProvider::PersonSerializer
      end

      private

      def find_user
        @retrieved_user = Spree::User.find(params[:id])
      end

      def check_user_accessibility
        return if @user == @retrieved_user

        not_found
      end
    end
  end
end
