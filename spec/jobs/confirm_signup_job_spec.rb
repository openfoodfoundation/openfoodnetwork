require 'spec_helper'

describe ConfirmSignupJob do
  let(:user) { create(:user) }

  it "sends a confirmation email to the user" do
    mail = double(:mail)
    Spree::UserMailer.should_receive(:signup_confirmation).with(user).and_return(mail)
    mail.should_receive(:deliver)

    run_job ConfirmSignupJob.new user.id
  end
end
