require 'spec_helper'
require 'support/request/authentication_workflow'

describe Spree::CreditCardsController do
  include AuthenticationWorkflow
  let(:user) { create_enterprise_user }

  it "Creates a credit card from token + params" do
    controller.stub(:spree_current_user) { user }
    controller.stub(:create_customer) {
      sc = Stripe::Customer.new
      sc.default_source = "card_1AEEbN2eZvKYlo2CMk6QwrN7"
      sc.email = nil
      sc.stub(:id) {"cus_AZNMJzuACN3Sgt"}
      sc }

    token = "tok_234bd2c22"
    expect{ post :new_from_token, {
      "exp_month" => 12,
      "exp_year" => 2020,
      "last4" => 4242,
      "token" => token,
      "cc_type" => "visa"
    } }.to change(Spree::CreditCard, :count).by(1)

    Spree::CreditCard.last.gateway_payment_profile_id.should eq "card_1AEEbN2eZvKYlo2CMk6QwrN7"
    Spree::CreditCard.last.gateway_customer_profile_id.should eq "cus_AZNMJzuACN3Sgt"
    Spree::CreditCard.last.user_id.should eq user.id
    Spree::CreditCard.last.last_digits.should eq "4242"
  end
end
