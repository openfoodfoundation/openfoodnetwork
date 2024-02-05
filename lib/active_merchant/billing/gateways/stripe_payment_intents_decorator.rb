# frozen_string_literal: true

ActiveMerchant::Billing::StripePaymentIntentsGateway.class_eval do
  CREATE_INTENT_ATTRIBUTES =
    %i[description statement_descriptor receipt_email save_payment_method].freeze

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
