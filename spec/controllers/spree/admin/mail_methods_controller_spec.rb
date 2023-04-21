# frozen_string_literal: true

require 'spec_helper'

describe Spree::Admin::MailMethodsController do
  include AuthenticationHelper

  before { controller_login_as_admin }

  context "#update" do
    it "should reinitialize the mail settings" do
      expect(Spree::Core::MailSettings).to receive(:init)
      spree_put :update, mails_from: "ofn@example.com"
    end
  end

  it "can trigger testmail" do
    request.env["HTTP_REFERER"] = "/"
    user = double('User', email: 'user@example.com',
                          spree_api_key: 'fake',
                          id: nil,
                          owned_groups: nil)
    allow(user).to receive_messages(enterprises: [create(:enterprise)],
                                    has_spree_role?: true,
                                    locale: nil)
    allow(controller).to receive_messages(spree_current_user: user)

    expect {
      spree_post :testmail
    }.to change { ActionMailer::Base.deliveries.size }.by(1)
  end
end
