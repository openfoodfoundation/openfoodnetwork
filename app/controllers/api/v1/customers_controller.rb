# frozen_string_literal: true

require 'open_food_network/permissions'

module Api
  module V1
    class CustomersController < Api::V1::BaseController
      skip_authorization_check only: :index

      before_action :set_customer, only: [:show, :update, :destroy]
      before_action :authorize_action, only: [:show, :update, :destroy]

      def index
        customers = search_customers

        render json: Api::V1::CustomerSerializer.new(customers, is_collection: true)
      end

      def show
        render json: Api::V1::CustomerSerializer.new(@customer)
      end

      def create
        authorize! :update, Enterprise.find(customer_params[:enterprise_id])
        @customer = Customer.new(customer_params)

        if @customer.save
          render json: Api::V1::CustomerSerializer.new(@customer), status: :created
        else
          invalid_resource! @customer
        end
      end

      def update
        if @customer.update(customer_params)
          render json: Api::V1::CustomerSerializer.new(@customer)
        else
          invalid_resource! @customer
        end
      end

      def destroy
        if @customer.destroy
          render json: Api::V1::CustomerSerializer.new(@customer)
        else
          invalid_resource! @customer
        end
      end

      private

      def set_customer
        @customer = Customer.find(params[:id])
      end

      def authorize_action
        authorize! action_name.to_sym, @customer
      end

      def search_customers
        customers = visible_customers
        customers = customers.where(enterprise_id: params[:enterprise_id]) if params[:enterprise_id]
        customers.ransack(params[:q]).result
      end

      def visible_customers
        Customer.where(user_id: current_api_user.id).or(Customer.where(enterprise_id: editable_enterprises))
      end

      def customer_params
        params.require(:customer).permit(:code, :email, :enterprise_id, :allow_charges)
      end

      def editable_enterprises
        OpenFoodNetwork::Permissions.new(current_api_user).editable_enterprises.select(:id)
      end
    end
  end
end
