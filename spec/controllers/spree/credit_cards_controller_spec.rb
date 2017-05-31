require 'spec_helper'
require 'support/request/authentication_workflow'

describe Spree::CreditCardsController do
  include AuthenticationWorkflow
  let(:user) { create_enterprise_user }
  let(:token) { "tok_234bd2c22" }

  before do
    Stripe.api_key = "sk_test_12345"
  end

  it "Creates a credit card from token + params" do
    controller.stub(:spree_current_user) { user }

    stub_request(:post, "https://api.stripe.com/v1/customers")
      .with(:body => { email: user.email, source: token })
      .to_return(status: 200, body: JSON.generate({ id: "cus_AZNMJ", default_source: "card_1AEEb" }))

    expect{ post :new_from_token, {
      "exp_month" => 12,
      "exp_year" => 2020,
      "last4" => 4242,
      "token" => token,
      "cc_type" => "visa"
    } }.to change(Spree::CreditCard, :count).by(1)

    Spree::CreditCard.last.gateway_payment_profile_id.should eq "card_1AEEb"
    Spree::CreditCard.last.gateway_customer_profile_id.should eq "cus_AZNMJ"
    Spree::CreditCard.last.user_id.should eq user.id
    Spree::CreditCard.last.last_digits.should eq "4242"
  end
end
