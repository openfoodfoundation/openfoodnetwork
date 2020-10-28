# frozen_string_literal: true

module Spree
  module Admin
    class PaymentsController < Spree::Admin::BaseController
      before_action :load_order, except: [:show]
      before_action :load_payment, only: [:fire, :show]
      before_action :load_data
      before_action :can_transition_to_payment

      respond_to :html

      def index
        @payments = @order.payments
        redirect_to spree.new_admin_order_payment_url(@order) if @payments.empty?
      end

      def new
        @payment = @order.payments.build
      end

      def create
        @payment = @order.payments.build(object_params)
        load_payment_source

        begin
          unless @payment.save
            redirect_to spree.admin_order_payments_path(@order)
            return
          end

          authorize_stripe_sca_payment

          if @order.completed?
            @payment.process!
            flash[:success] = flash_message_for(@payment, :successfully_created)

            redirect_to spree.admin_order_payments_path(@order)
          else
            OrderWorkflow.new(@order).complete!

            flash[:success] = Spree.t(:new_order_completed)
            redirect_to spree.edit_admin_order_url(@order)
          end
        rescue Spree::Core::GatewayError => e
          flash[:error] = e.message.to_s
          redirect_to spree.new_admin_order_payment_path(@order)
        end
      end

      # When a user fires an event, take them back to where they came from
      # (we can't use respond_override because Spree no longer uses respond_with)
      def fire
        event = params[:e]
        return unless event && @payment.payment_source

        # Because we have a transition method also called void, we do this to avoid conflicts.
        event = "void_transaction" if event == "void"
        if @payment.public_send("#{event}!")
          flash[:success] = t(:payment_updated)
        else
          flash[:error] = t(:cannot_perform_operation)
        end
      rescue StandardError => e
        flash[:error] = e.message
      ensure
        redirect_to request.referer
      end

      private

      def load_payment_source
        if @payment.payment_method.is_a?(Spree::Gateway) &&
           @payment.payment_method.payment_profiles_supported? &&
           params[:card].present? &&
           (params[:card] != 'new')
          @payment.source = CreditCard.find_by(id: params[:card])
        end
      end

      def object_params
        if params[:payment] &&
           params[:payment_source] &&
           source_params = params.delete(:payment_source)[params[:payment][:payment_method_id]]
          params[:payment][:source_attributes] = source_params
        end

        params.require(:payment).permit(
          :amount, :payment_method_id,
          source_attributes: ::PermittedAttributes::PaymentSource.attributes
        )
      end

      def load_data
        @amount = params[:amount] || load_order.total

        # Only show payments for the order's distributor
        @payment_methods = PaymentMethod.
          available(:back_end).
          select{ |pm| pm.has_distributor? @order.distributor }

        @payment_method = if @payment&.payment_method
                            @payment.payment_method
                          else
                            @payment_methods.first
                          end

        @previous_cards = @order.credit_cards.with_payment_profile
      end

      # At this point admin should have passed through Customer Details step
      # where order.next is called which leaves the order in payment step
      #
      # Orders in complete step also allows to access this controller
      #
      # Otherwise redirect user to that step
      def can_transition_to_payment
        return if @order.payment? || @order.complete?

        flash[:notice] = Spree.t(:fill_in_customer_info)
        redirect_to spree.edit_admin_order_customer_url(@order)
      end

      def load_order
        @order = Order.find_by!(number: params[:order_id])
        authorize! action, @order
        @order
      end

      def load_payment
        @payment = Payment.find(params[:id])
      end

      def authorize_stripe_sca_payment
        return unless @payment.payment_method.class == Spree::Gateway::StripeSCA

        @payment.authorize!
        raise Spree::Core::GatewayError, I18n.t('authorization_failure') unless @payment.pending?
      end
    end
  end
end
