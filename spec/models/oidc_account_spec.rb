# frozen_string_literal: true

require 'spec_helper'

describe OidcAccount, type: :model do
  describe "associations and validations" do
    subject {
      OidcAccount.new(
        user: build(:user),
        provider: "openid_connect",
        uid: "user@example.net"
      )
    }

    it { is_expected.to belong_to :user }
    it { is_expected.to validate_uniqueness_of :uid }
  end

  describe ".link" do
    let(:user) { create(:user, email: "user@example.com") }
    let(:auth) {
      OmniAuth::AuthHash.new(
        provider: "openid_connect",
        uid: "user@example.net"
      )
    }

    it "creates or updates an account record" do
      expect { OidcAccount.link(user, auth) }
        .to change { OidcAccount.count }.by(1)

      account = OidcAccount.last
      expect(account.user).to eq user
      expect(account.provider).to eq "openid_connect"

      auth.uid = "user@example.org"

      expect {
        OidcAccount.link(user, auth)
        account.reload
      }
        .to change { OidcAccount.count }.by(0)
        .and change { account.uid }
        .from("user@example.net").to("user@example.org")
    end
  end
end
