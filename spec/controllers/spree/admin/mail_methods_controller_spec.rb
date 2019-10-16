require 'spec_helper'

describe Spree::Admin::MailMethodsController do
  include AuthenticationWorkflow

  before { login_as_admin }

  context "#update" do
    it "should reinitialize the mail settings" do
      expect(Spree::Core::MailSettings).to receive(:init)
      spree_put :update, enable_mail_delivery: "1", mails_from: "spree@example.com"
    end
  end

  it "can trigger testmail" do
    request.env["HTTP_REFERER"] = "/"
    user = double('User', email: 'user@spree.com',
                          spree_api_key: 'fake',
                          id: nil,
                          owned_groups: nil)
    allow(user).to receive_messages(enterprises: [create(:enterprise)], has_spree_role?: true)
    allow(controller).to receive_messages(try_spree_current_user: user)
    Spree::Config[:enable_mail_delivery] = "1"
    ActionMailer::Base.perform_deliveries = true

    expect {
      spree_post :testmail
    }.to change { ActionMailer::Base.deliveries.size }.by(1)
  end
end
