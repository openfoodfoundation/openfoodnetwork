# frozen_string_literal: true

module Api
  module V1
    class CustomersController < Api::V1::BaseController
      def index
        #
      end

      def show
        #
      end

      def update
        #
      end

      def destroy
        #
      end

      private

      def customer_params
        params.require(:customer).permit(:code, :email, :enterprise_id, :allow_charges)
      end
    end
  end
end
