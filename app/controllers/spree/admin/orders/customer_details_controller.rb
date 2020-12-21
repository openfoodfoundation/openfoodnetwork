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
          country_id = Address.default.country.id
          @order.build_bill_address(country_id: country_id) if @order.bill_address.nil?
          @order.build_ship_address(country_id: country_id) if @order.ship_address.nil?
        end

        def update
          if @order.update(order_params)
            if params[:guest_checkout] == "false"
              @order.associate_user!(Spree.user_class.find_by(email: @order.email))
            end

            OrderWorkflow.new(@order).complete

            @order.shipments.map(&:refresh_rates)
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

        def order_params
          params.require(:order).permit(
            :email,
            :use_billing,
            bill_address_attributes: ::PermittedAttributes::Address.attributes,
            ship_address_attributes: ::PermittedAttributes::Address.attributes
          )
        end

        def load_order
          @order = Order.find_by!({ number: params[:order_id] }, include: :adjustments)
        end

        def check_authorization
          load_order
          session[:access_token] ||= params[:token]

          resource = @order
          action = params[:action].to_sym
          action = :edit if action == :show # show route renders :edit for this controller

          authorize! action, resource, session[:access_token]
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
