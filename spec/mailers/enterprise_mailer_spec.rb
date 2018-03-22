require 'spec_helper'

describe EnterpriseMailer do
  let!(:enterprise) { create(:enterprise) }

  before do
    ActionMailer::Base.deliveries = []
    Spree::MailMethod.create!(environment: 'test')
  end

  it "sends a welcome email when given an enterprise" do
    EnterpriseMailer.welcome(enterprise).deliver

    mail = ActionMailer::Base.deliveries.first
    expect(mail.subject)
      .to eq "#{enterprise.name} is now on #{Spree::Config[:site_name]}"
  end
end
