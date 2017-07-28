require 'spec_helper'

describe EnterpriseMailer do
  let!(:enterprise) { create(:enterprise) }

  before do
    ActionMailer::Base.deliveries = []
  end

  it "should send a welcome email when given an enterprise" do
    EnterpriseMailer.welcome(enterprise).deliver
    ActionMailer::Base.deliveries.count.should == 1
    mail = ActionMailer::Base.deliveries.first
    expect(mail.subject).to eq "#{enterprise.name} is now on #{Spree::Config[:site_name]}"
  end
end
