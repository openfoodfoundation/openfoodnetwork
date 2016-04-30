require 'spec_helper'

describe EnterpriseMailer do
  let!(:enterprise) { create(:enterprise) }

  before do
    ActionMailer::Base.deliveries = []
  end

  context "when given an enterprise without an unconfirmed_email" do
    it "should send an email confirmation to email" do
      EnterpriseMailer.confirmation_instructions(enterprise, 'token').deliver
      ActionMailer::Base.deliveries.count.should == 1
      mail = ActionMailer::Base.deliveries.first
      expect(mail.subject).to eq "Please confirm the email address for #{enterprise.name}"
      expect(mail.to).to include enterprise.email
      expect(mail.reply_to).to be_nil
    end
  end

  context "when given an enterprise with an unconfirmed_email" do
    before do
      enterprise.unconfirmed_email = "unconfirmed@email.com"
      enterprise.save!
    end

    it "should send an email confirmation to unconfirmed_email" do
      EnterpriseMailer.confirmation_instructions(enterprise, 'token').deliver
      ActionMailer::Base.deliveries.count.should == 1
      mail = ActionMailer::Base.deliveries.first
      expect(mail.subject).to eq "Please confirm the email address for #{enterprise.name}"
      expect(mail.to).to include enterprise.unconfirmed_email
    end
  end

  it "should send a welcome email when given an enterprise" do
    EnterpriseMailer.welcome(enterprise).deliver
    ActionMailer::Base.deliveries.count.should == 1
    mail = ActionMailer::Base.deliveries.first
    expect(mail.subject).to eq "#{enterprise.name} is now on #{Spree::Config[:site_name]}"
  end
end
