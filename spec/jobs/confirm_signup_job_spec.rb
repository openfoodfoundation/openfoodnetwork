require 'spec_helper'

describe ConfirmSignupJob do
  let(:user) { create(:user) }

  it "sends a confirmation email to the user" do
    mail = double(:mail)
    expect(Spree::UserMailer).to receive(:signup_confirmation).with(user).and_return(mail)
    expect(mail).to receive(:deliver)

    ConfirmSignupJob.perform_now(user.id)
  end
end
