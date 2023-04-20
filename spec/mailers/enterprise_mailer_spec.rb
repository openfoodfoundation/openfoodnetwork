# frozen_string_literal: true

require 'spec_helper'

describe EnterpriseMailer do
  let!(:enterprise) { create(:enterprise) }
  let!(:user) { create(:user) }

  describe "#welcome" do
    it "sends a welcome email when given an enterprise" do
      EnterpriseMailer.welcome(enterprise).deliver_now

      mail = ActionMailer::Base.deliveries.first
      expect(mail.subject)
        .to eq "#{enterprise.name} is now on #{Spree::Config[:site_name]}"
    end
  end

  describe "#manager_invitation" do
    it "should send a manager invitation email when given an enterprise and user" do
      EnterpriseMailer.manager_invitation(enterprise, user).deliver_now
      expect(ActionMailer::Base.deliveries.count).to eq 1
      mail = ActionMailer::Base.deliveries.first
      expect(mail.subject).to eq "#{enterprise.name} has invited you to be a manager"
    end
  end
end
