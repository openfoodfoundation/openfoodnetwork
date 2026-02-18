# frozen_string_literal: true

RSpec.describe EnterpriseMailer do
  let(:enterprise) { build(:enterprise, name: "Fred's Farm") }

  describe "#welcome" do
    subject(:mail) { EnterpriseMailer.welcome(enterprise) }

    it "sends a welcome email when given an enterprise" do
      expect(mail.subject)
        .to eq "Fred's Farm is now on OFN Demo Site"
    end

    it "does not set a reply-to email" do
      expect(mail.reply_to).to eq nil
    end
  end

  describe "#manager_invitation" do
    subject(:mail) { EnterpriseMailer.manager_invitation(enterprise, user) }
    let(:user) { build(:user) }

    it "should send a manager invitation email when given an enterprise and user" do
      expect(mail.subject).to eq "Fred's Farm has invited you to be a manager"
    end

    it "sets a reply-to of the enterprise email" do
      expect(mail.reply_to).to eq([enterprise.contact.email])
    end
  end
end
