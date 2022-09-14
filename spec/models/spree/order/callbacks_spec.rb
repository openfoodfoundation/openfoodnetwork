# frozen_string_literal: true

require 'spec_helper'

describe Spree::Order do
  let(:order) { build(:order) }
  before do
    Spree::Order.define_state_machine!
  end

  context "validations" do
    context "email validation" do
      # Regression test for Spree #1238
      it "o'brien@gmail.com is a valid email address" do
        order.state = 'address'
        order.email = "o'brien@gmail.com"
        expect(order.errors[:email]).to be_empty
      end
    end
  end

  context "#save" do
    context "when associated with a registered user" do
      let(:user) { Spree::User.new(email: "test@example.com") }

      before do
        order.user = user
      end

      it "should assign the email address of the user" do
        order.run_callbacks(:create)
        expect(order.email).to eq user.email
      end
    end
  end

  context "in the cart state" do
    it "should not validate email address" do
      order.state = "cart"
      order.email = nil
      expect(order.errors[:email]).to be_empty
    end
  end
end
