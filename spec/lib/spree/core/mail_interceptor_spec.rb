# frozen_string_literal: true

require 'spec_helper'

# Here we use the OrderMailer as a way to test the mail interceptor.
describe Spree::OrderMailer do
  let(:order) do
    Spree::Order.new(distributor: create(:enterprise),
                     bill_address: create(:address))
  end
  let(:message) { Spree::OrderMailer.confirm_email_for_shop(order) }

  before(:all) do
    ActionMailer::Base.deliveries.clear
  end

  context "#deliver" do
    after { ActionMailer::Base.deliveries.clear }

    it "should use the from address specified in the preference" do
      Spree::Config[:mails_from] = "no-reply@foobar.com"
      message.deliver_now
      @email = ActionMailer::Base.deliveries.first
      expect(@email.from).to eq ["no-reply@foobar.com"]
    end

    it "should use the provided from address" do
      Spree::Config[:mails_from] = "preference@foobar.com"
      message.from = "override@foobar.com"
      message.to = "test@test.com"
      message.deliver_now
      email = ActionMailer::Base.deliveries.first
      expect(email.from).to eq ["override@foobar.com"]
      expect(email.to).to eq ["test@test.com"]
    end

    it "should add the bcc email when provided" do
      Spree::Config[:mail_bcc] = "bcc-foo@foobar.com"
      message.deliver_now
      @email = ActionMailer::Base.deliveries.first
      expect(@email.bcc).to eq ["bcc-foo@foobar.com"]
    end

    context "when intercept_email is provided" do
      it "should strip the bcc recipients" do
        expect(message.bcc).to be_blank
      end

      it "should strip the cc recipients" do
        expect(message.cc).to be_blank
      end

      it "should replace the receipient with the specified address" do
        Spree::Config[:intercept_email] = "intercept@foobar.com"
        message.deliver_now
        @email = ActionMailer::Base.deliveries.first
        expect(@email.to).to eq ["intercept@foobar.com"]
      end

      it "should modify the subject to include the original email" do
        Spree::Config[:intercept_email] = "intercept@foobar.com"
        message.deliver_now
        @email = ActionMailer::Base.deliveries.first
        expect(@email.subject).to include order.distributor.contact.email
      end
    end

    context "when intercept_mode is not provided" do
      it "should not modify the recipient" do
        Spree::Config[:intercept_email] = ""
        message.deliver_now
        @email = ActionMailer::Base.deliveries.first
        expect(@email.to).to eq [order.distributor.contact.email]
      end
    end
  end
end
