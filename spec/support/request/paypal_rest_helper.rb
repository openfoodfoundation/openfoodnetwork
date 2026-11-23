# frozen_string_literal: true

module PaypalRestHelper
  def stub_paypal_rest_client(amount:, approval_url: 'https://paypal.example/approve',
                              order_id: 'ORDER-1', capture_id: 'CAPTURE-1')
    client = instance_double(PaypalRest::Client)
    allow(PaypalRest::Client).to receive(:new).and_return(client)

    allow(client).to receive(:create_order).and_return(
      PaypalRest::Result.new(
        success: true, order_id:, approval_url:, status: 'CREATED'
      )
    )
    allow(client).to receive(:order_amount).and_return(
      PaypalRest::Result.new(success: true, amount: format('%.2f', amount), currency_code: 'AUD')
    )
    allow(client).to receive(:capture_order).and_return(
      PaypalRest::Result.new(
        success: true, order_id:, capture_id:, payer_id: 'PAYER-1', status: 'COMPLETED'
      )
    )

    client
  end
end
