# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EnterpriseMailer do
  let!(:enterprise) { create(:enterprise) }
  let!(:user) { create(:user) }

  describe "#welcome" do
    subject(:mail) { EnterpriseMailer.welcome(enterprise) }

    it "sends a welcome email when given an enterprise" do
      expect(mail.subject)
        .to eq "#{enterprise.name} is now on #{Spree::Config[:site_name]}"
    end

    it "does not set a reply-to email" do
      expect(mail.reply_to).to eq nil
    end
  end

  describe "#manager_invitation" do
    subject(:mail) { EnterpriseMailer.manager_invitation(enterprise, user) }

    it "should send a manager invitation email when given an enterprise and user" do
      expect(mail.subject).to eq "#{enterprise.name} has invited you to be a manager"
    end

    it "sets a reply-to of the enterprise email" do
      expect(mail.reply_to).to eq([enterprise.contact.email])
    end
  end
end
