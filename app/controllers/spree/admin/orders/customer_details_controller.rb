# frozen_string_literal: true

module Spree
  module Admin
    module Orders
      class CustomerDetailsController < Spree::Admin::BaseController
        before_action :load_order
        before_action :check_authorization
        before_action :set_guest_checkout_status, only: :update

        def show
          edit
          render action: :edit
        end

        def edit
          build_addresses
        end

        def update
          if update_order_and_customer
            if params[:guest_checkout] == "false"
              @order.associate_user!(Spree::User.find_by(email: @order.email))
            end

            refresh_shipment_rates
            ::Orders::WorkflowService.new(@order).advance_to_payment

            flash[:success] = Spree.t('customer_details_updated')
            redirect_to spree.admin_order_customer_path(@order)
          else
            render action: :edit
          end
        end

        # Inherit CanCan permissions for the current order
        def model_class
          load_order unless @order
          @order
        end

        private

        # The customer is updated after the order so it applies to the customer
        # selected in the form. Cart orders don't have one yet: create it now.
        def update_order_and_customer
          Order.transaction do
            (@order.update(order_params) && update_customer) || raise(ActiveRecord::Rollback)
          end
        end

        def update_customer
          return true if params[:customer].blank?

          @order.customer ||= CustomerSyncer.create_customer(@order)
          @order.customer.update(customer_params) && @order.save
        end

        def build_addresses
          country_id = Address.default.country.id
          @order.build_bill_address(country_id:) if @order.bill_address.nil?
          @order.build_ship_address(country_id:) if @order.ship_address.nil?
        end

        def refresh_shipment_rates
          @order.shipments.map(&:refresh_rates)
        end

        def order_params
          params.require(:order).permit(
            :email,
            :use_billing,
            :customer_id,
            bill_address_attributes: ::PermittedAttributes::Address.attributes,
            ship_address_attributes: ::PermittedAttributes::Address.attributes
          )
        end

        def customer_params
          params.require(:customer).permit(
            :customer_type, :enterprise_name, :enterprise_acn, :enterprise_abn,
            :enterprise_charges_sales_tax
          )
        end

        def load_order
          @order = Order.find_by!({ number: params[:order_id] }, include: :adjustments)
        end

        def check_authorization
          action = params[:action].to_sym
          action = :edit if action == :show # show route renders :edit for this controller

          authorize! action, @order
        end

        def set_guest_checkout_status
          registered_user = Spree::User.find_by(email: params[:order][:email])

          params[:order][:guest_checkout] = registered_user.nil?

          return unless registered_user

          @order.user_id = registered_user.id
        end
      end
    end
  end
end
