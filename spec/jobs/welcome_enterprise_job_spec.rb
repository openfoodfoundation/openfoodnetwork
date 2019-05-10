require 'spec_helper'

describe WelcomeEnterpriseJob do
  let(:enterprise) { create(:enterprise) }

  it "sends a welcome email to the enterprise" do
    mail = double(:mail)
    expect(EnterpriseMailer).to receive(:welcome).with(enterprise).and_return(mail)
    expect(mail).to receive(:deliver)

    run_job WelcomeEnterpriseJob.new(enterprise.id)
  end
end
