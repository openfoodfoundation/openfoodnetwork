require 'spec_helper'

describe Spree::UserMailer do
  let(:user) { build(:user) }
  let(:mail_method) { Spree::MailMethod.new(:environment => "test", :preferred_mails_from => 'spec-test@openfoodnetwork.org') }

  after do
    ActionMailer::Base.deliveries.clear
  end

  before do
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    Spree::MailMethod.stub :current => mail_method
  end

  it "sends an email when given a user" do
    Spree::UserMailer.signup_confirmation(user).deliver
    ActionMailer::Base.deliveries.count.should == 1
  end

  it "uses the preferred from email" do
    Spree::UserMailer.signup_confirmation(user).deliver
    ActionMailer::Base.deliveries.first.body.should include 'spec-test@openfoodnetwork.org'
  end
end
