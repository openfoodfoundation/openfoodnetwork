# frozen_string_literal: true

module PaypalRest
  class Client
    include ResponseNormalizers

    def initialize(client_id:, client_secret:, environment:)
      @sdk = PaypalServerSdk::Client.new(
        client_credentials_auth_credentials:
          PaypalServerSdk::ClientCredentialsAuthCredentials.new(
            o_auth_client_id: client_id,
            o_auth_client_secret: client_secret
          ),
        environment:
          if environment == "live"
            PaypalServerSdk::Environment::PRODUCTION
          else
            PaypalServerSdk::Environment::SANDBOX
          end
      )
    end

    def create_order(order_request, request_id: nil)
      options = { "body" => order_request, "paypal_request_id" => request_id }.compact
      normalize_order(@sdk.orders.create_order(options))
    rescue PaypalServerSdk::APIException, SocketError => e
      failure(e.message)
    end

    def order_amount(order_id, request_id: nil)
      options = { "id" => order_id, "paypal_request_id" => request_id }.compact
      normalize_order_amount(@sdk.orders.get_order(options))
    rescue PaypalServerSdk::APIException, SocketError => e
      failure(e.message)
    end

    def capture_order(order_id, order_capture_request = {}, request_id: nil)
      options = {
        "id" => order_id, "body" => order_capture_request, "paypal_request_id" => request_id
      }.compact
      normalize_capture(@sdk.orders.capture_order(options))
    rescue PaypalServerSdk::APIException, SocketError => e
      failure(e.message)
    end

    def refund_capture(capture_id, refund_request, request_id: nil)
      options = {
        "capture_id" => capture_id, "body" => refund_request, "paypal_request_id" => request_id
      }.compact
      normalize_refund(@sdk.payments.refund_captured_payment(options))
    rescue PaypalServerSdk::APIException, SocketError => e
      failure(e.message)
    end
  end
end
