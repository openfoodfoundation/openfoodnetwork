# frozen_string_literal: true

module Spree
  class Payment < ApplicationRecord
    module Processing
      def process!
        return unless validate!

        purchase!
      end

      def process_offline!
        return unless validate!
        return if requires_authorization?

        if preauthorized?
          capture!
        else
          charge_offline!
        end
      end

      def authorize!(return_url = nil)
        started_processing!
        gateway_action(source, :authorize, :pend, return_url:)
      end

      def purchase!
        started_processing!
        gateway_action(source, :purchase, :complete)
      end

      def charge_offline!
        started_processing!
        gateway_action(source, :charge_offline, :complete)
      end

      def capture!
        return true if completed?

        started_processing!
        protect_from_connection_error do
          check_environment
          response = payment_method.capture(money.money.cents, response_code, gateway_options)

          handle_response(response, :complete, :failure)
        end
      end

      def capture_and_complete_order!
        Orders::WorkflowService.new(order).complete!
        capture!
      end

      def void_transaction!
        return true if void?

        protect_from_connection_error do
          check_environment

          response = payment_method.void(response_code, gateway_options)

          record_response(response)

          if response.success?
            self.response_code = response.authorization
            void
          else
            gateway_error(response)
          end
        end
      end

      def credit!(credit_amount = nil)
        protect_from_connection_error do
          check_environment

          credit_amount = calculate_refund_amount(credit_amount)

          response = payment_method.credit(
            (credit_amount * 100).round,
            response_code,
            gateway_options
          )

          record_response(response)

          if response.success?
            self.class.create!(
              order:,
              source: self,
              payment_method:,
              amount: credit_amount.abs * -1,
              response_code: response.authorization,
              state: 'completed',
              skip_source_validation: true
            )
          else
            gateway_error(response)
          end
        end
      end

      def refund!(refund_amount = nil)
        protect_from_connection_error do
          check_environment

          refund_amount = calculate_refund_amount(refund_amount)

          response = if payment_method.payment_profiles_supported?
                       payment_method.refund(
                         (refund_amount * 100).round,
                         source,
                         response_code,
                         gateway_options
                       )
                     else
                       payment_method.refund(
                         (refund_amount * 100).round,
                         response_code,
                         gateway_options
                       )
                     end

          record_response(response)

          if response.success?
            self.class.create!(
              order:,
              source: self,
              payment_method:,
              amount: refund_amount.abs * -1,
              response_code: response.authorization,
              state: 'completed',
              skip_source_validation: true
            )
          else
            gateway_error(response)
          end
        end
      end

      def partial_credit(amount)
        return if amount > credit_allowed

        started_processing!
        credit!(amount)
      end

      def gateway_options
        options = { email: order.email,
                    customer: order.email,
                    ip: order.last_ip_address,
                    # Need to pass in a unique identifier here to make some
                    # payment gateways happy.
                    #
                    # For more information, please see Spree::Payment#set_unique_identifier
                    order_id: gateway_order_id }

        options.merge!(shipping: order.ship_total * 100,
                       tax: order.additional_tax_total * 100,
                       subtotal: order.item_total * 100,
                       discount: 0,
                       currency:)

        options.merge!({ billing_address: order.bill_address.try(:active_merchant_hash),
                         shipping_address: order.ship_address.try(:active_merchant_hash) })
        options.merge!(payment: self)

        options
      end

      private

      def preauthorized?
        response_code.presence&.match("pi_")
      end

      def validate!
        return false unless payment_method&.source_required?

        raise Core::GatewayError, Spree.t(:payment_processing_failed) unless source

        return false if processing?

        unless payment_method.supports?(source)
          invalidate!
          raise Core::GatewayError, Spree.t(:payment_method_not_supported)
        end
        true
      end

      def calculate_refund_amount(refund_amount = nil)
        refund_amount ||= if credit_allowed >= order.outstanding_balance.abs
                            order.outstanding_balance.abs
                          else
                            credit_allowed.abs
                          end
        refund_amount.to_f
      end

      def gateway_action(source, action, success_state, options = {})
        protect_from_connection_error do
          check_environment

          response = payment_method.public_send(
            action,
            (amount * 100).round,
            source,
            gateway_options.merge(options)
          )
          handle_response(response, success_state, :failure)
        end
      end

      def handle_response(response, success_state, failure_state)
        record_response(response)

        if response.success?
          unless response.authorization.nil?
            self.response_code = response.authorization
            self.avs_response = response.avs_result['code']

            if response.cvv_result
              self.cvv_response_code = response.cvv_result['code']
              self.cvv_response_message = response.cvv_result['message']
              self.redirect_auth_url = response.cvv_result['redirect_auth_url']
              if redirect_auth_url.present?
                return require_authorization!
              end
            end
          end
          __send__("#{success_state}!")
        else
          __send__(failure_state)
          gateway_error(response)
        end
      end

      def record_response(response)
        log_entries.create(details: response.to_yaml)
      end

      def protect_from_connection_error
        yield
      rescue ActiveMerchant::ConnectionError => e
        gateway_error(e)
      end

      def gateway_error(error)
        text = if error.is_a? ActiveMerchant::Billing::Response
                 error_text(error)
               elsif error.is_a? ActiveMerchant::ConnectionError
                 Spree.t(:unable_to_connect_to_gateway)
               else
                 error.to_s
               end
        logger.error(Spree.t(:gateway_error))
        logger.error("  #{error.to_yaml}")
        raise Core::GatewayError, text
      end

      def error_text(error)
        if (code = error.params.dig('error', 'code')) && I18n.exists?("stripe.error_code.#{code}")
          I18n.t("stripe.error_code.#{code}")
        else
          error.params['message'] || error.params['response_reason_text'] || error.message
        end
      end

      # Saftey check to make sure we're not accidentally performing operations on a live gateway.
      # Ex. When testing in staging environment with a copy of production data.
      def check_environment
        return if payment_method.environment == Rails.env

        message = Spree.t(:gateway_config_unavailable) + " - #{Rails.env}"
        raise Core::GatewayError, message
      end

      # The unique identifier to be passed in to the payment gateway
      def gateway_order_id
        "#{order.number}-#{identifier}"
      end
    end
  end
end
