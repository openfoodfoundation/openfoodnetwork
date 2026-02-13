# frozen_string_literal: true

RSpec.describe UserInvitation do
  let(:enterprise) { create(:distributor_enterprise) }
  let(:defaults) { { enterprise: enterprise } }

  describe "#validations" do
    it "validates the presence of :email and :enterprise" do
      user_invitation = UserInvitation.new(defaults.merge(email: nil, enterprise: nil))
      user_invitation.valid?

      expect(user_invitation.errors[:email]).to eq ["can't be blank"]
      expect(user_invitation.errors[:enterprise]).to eq ["can't be blank"]
    end

    it "validates the email format" do
      user_invitation = UserInvitation.new(defaults.merge(email: "invalid_email"))
      user_invitation.valid?

      expect(user_invitation.errors[:email]).to eq ["is invalid"]
    end

    it "validates the email is not already a user on the enterprise" do
      user_invitation = UserInvitation.new(defaults.merge(email: enterprise.owner.email))
      user_invitation.valid?

      expect(user_invitation.errors[:email]).to eq ["is already a manager"]
    end

    it "validates the email domain has a MX record" do
      user_invitation = UserInvitation.new(defaults.merge(email: "newuser@example.invaliddomain"))
      expect_any_instance_of(ValidEmail2::Address).to receive(:valid_mx?).and_return(false)
      user_invitation.valid?

      expect(user_invitation.errors[:email]).to eq ["is invalid"]
    end
  end

  context "inviting a new user" do
    it "creates a new unconfirmed user, adds thems to the enterprise and sends them an invitation
        email" do
      user_invitation = UserInvitation.new(defaults.merge(email: "new_user@example.com"))

      expect do
        user_invitation.save!
      end.to have_enqueued_mail(EnterpriseMailer, :manager_invitation)

      new_user = Spree::User.find_by(email: "new_user@example.com")
      expect(new_user).not_to be_confirmed
      expect(new_user.unconfirmed_email).to eq("new_user@example.com")
      expect(enterprise.users).to include(new_user)
    end
  end

  context "inviting a existing user who isn't a user on the enterprise" do
    it "adds the user to the enterprise and sends them an invitation email" do
      existing_user = create(:user)
      user_invitation = UserInvitation.new(defaults.merge(email: existing_user.email))

      expect do
        user_invitation.save!
      end.to have_enqueued_mail(EnterpriseMailer, :manager_invitation)

      expect(enterprise.users).to include(existing_user)
    end
  end
end
