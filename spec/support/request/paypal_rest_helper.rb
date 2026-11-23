# frozen_string_literal: true

module PaypalRestHelper
  def stub_paypal_rest_client(approval_result: nil, amount_result: nil, capture_result: nil)
    client = instance_double(PaypalRest::Client)
    allow(PaypalRest::Client).to receive(:new).and_return(client)

    allow(client).to receive(:create_order).and_return(
      approval_result || PaypalRest::Result.new(
        success: true,
        order_id: 'ORDER-1',
        approval_url: 'https://paypal.example/approve',
        status: 'CREATED'
      )
    )
    allow(client).to receive(:order_amount).and_return(
      amount_result || PaypalRest::Result.new(success: true, amount: '10.00', currency_code: 'AUD')
    )
    allow(client).to receive(:capture_order).and_return(
      capture_result || PaypalRest::Result.new(
        success: true,
        order_id: 'ORDER-1',
        capture_id: 'CAPTURE-1',
        payer_id: 'PAYER-1',
        status: 'COMPLETED'
      )
    )

    client
  end
end
