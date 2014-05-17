require 'spec_helper'

describe Spree::UserMailer do
  let(:user) { build(:user) }
  
  after do
    ActionMailer::Base.deliveries.clear
  end

  before do
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
  end

  it "sends an email when given a user" do
    Spree::UserMailer.signup_confirmation(user).deliver
    ActionMailer::Base.deliveries.count.should == 1
  end
end
