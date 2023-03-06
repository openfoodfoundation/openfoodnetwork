# frozen_string_literal: true

require 'open_food_network/permissions'

module Api
  module V1
    class CustomersController < Api::V1::BaseController
      include AddressTransformation

      skip_authorization_check only: :index

      before_action :authorize_action, only: [:show, :update, :destroy]

      def index
        @pagy, customers = pagy(search_customers, pagy_options)

        render json: Api::V1::CustomerSerializer.new(customers, pagination_options)
      end

      def show
        render json: Api::V1::CustomerSerializer.new(customer, include_options)
      end

      def create
        authorize! :update, Enterprise.find(customer_params[:enterprise_id])
        customer = Customer.new(customer_params)

        if customer.save
          render json: Api::V1::CustomerSerializer.new(customer), status: :created
        else
          invalid_resource! customer
        end
      end

      def update
        if customer.update(customer_params)
          render json: Api::V1::CustomerSerializer.new(customer)
        else
          invalid_resource! customer
        end
      end

      def destroy
        if customer.destroy
          render json: Api::V1::CustomerSerializer.new(customer)
        else
          invalid_resource! customer
        end
      end

      private

      def customer
        @customer ||= Customer.find(params[:id])
      end

      def authorize_action
        authorize! action_name.to_sym, customer
      end

      def search_customers
        customers = visible_customers.includes(:bill_address, :ship_address)
        customers = customers.where(enterprise_id: params[:enterprise_id]) if params[:enterprise_id]
        customers.ransack(params[:q]).result.order(:id)
      end

      def visible_customers
        current_api_user.customers.or(
          Customer.where(enterprise_id: editable_enterprises)
        )
      end

      def customer_params
        attributes = params.require(:customer).permit(
          :email, :enterprise_id,
          :code, :first_name, :last_name,
          :billing_address, shipping_address: [
            :phone, :latitude, :longitude,
            :first_name, :last_name,
            :street_address_1, :street_address_2,
            :postal_code, :locality,
            { region: [:name, :code], country: [:name, :code] },
          ]
        ).to_h

        attributes.merge!(tag_list: params[:tags]) if params.key?(:tags)

        transform_address!(attributes, :billing_address, :bill_address)
        transform_address!(attributes, :shipping_address, :ship_address)

        attributes
      end

      def editable_enterprises
        OpenFoodNetwork::Permissions.new(current_api_user).editable_enterprises.select(:id)
      end

      def include_options
        fields = [params.fetch(:include, [])].flatten

        { include: fields.map(&:to_s) }
      end
    end
  end
end
