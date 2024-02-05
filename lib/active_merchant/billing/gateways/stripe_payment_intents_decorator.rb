# frozen_string_literal: true

ActiveMerchant::Billing::StripePaymentIntentsGateway.class_eval do
  CREATE_INTENT_ATTRIBUTES =
    %i[description statement_descriptor receipt_email save_payment_method].freeze

  def create_intent(money, payment_method, options = {})
    post = {}
    add_amount(post, money, options, true)
    add_capture_method(post, options)
    add_confirmation_method(post, options)
    add_customer(post, options)
    add_payment_method_token(post, payment_method, options)
    add_metadata(post, options)
    add_return_url(post, options)
    add_connected_account(post, options)
    add_shipping_address(post, options)
    setup_future_usage(post, options)

    CREATE_INTENT_ATTRIBUTES.each do |attribute|
      add_whitelisted_attribute(post, options, attribute)
    end

    commit(:post, 'payment_intents', post, options)
  end

  def capture(money, intent_id, options = {})
    post = {}
    post[:amount_to_capture] = money
    add_connected_account(post, options)
    commit(:post, "payment_intents/#{intent_id}/capture", post, options)
  end

  def refund(money, intent_id, options = {})
    intent = commit(:get, "payment_intents/#{intent_id}", nil, options)
    charge_id = intent.params.dig('charges', 'data')[0]['id']
    super(money, charge_id, options)
  end

  private

  def add_connected_account(post, options = {})
    return unless transfer_data = options[:transfer_data]

    post[:transfer_data] = {}
    if transfer_data[:destination]
      post[:transfer_data][:destination] = transfer_data[:destination]
    end
    post[:transfer_data][:amount] = transfer_data[:amount] if transfer_data[:amount]
    post[:on_behalf_of] = options[:on_behalf_of] if options[:on_behalf_of]
    post[:transfer_group] = options[:transfer_group] if options[:transfer_group]
    post[:application_fee_amount] = options[:application_fee] if options[:application_fee]
    post
  end
end
