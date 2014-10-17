require 'spec_helper'

describe EnterpriseMailer do
  let!(:enterprise) { create(:enterprise) }

  before do
    ActionMailer::Base.deliveries = []
  end

  it "should send an email confirmation when given an enterprise" do
    EnterpriseMailer.confirmation_instructions(enterprise, 'token').deliver
    ActionMailer::Base.deliveries.count.should == 1
    mail = ActionMailer::Base.deliveries.first
    expect(mail.subject).to eq "Please confirm your email for #{enterprise.name}"
  end
end