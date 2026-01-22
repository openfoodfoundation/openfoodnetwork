# frozen_string_literal: true

RSpec.describe OidcAccount do
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
        JSON.parse(file_fixture("omniauth.auth.json").read)
      )
    }

    it "creates or updates an account record" do
      expect { OidcAccount.link(user, auth) }
        .to change { OidcAccount.count }.by(1)

      account = OidcAccount.last
      expect(account.user).to eq user
      expect(account.provider).to eq "openid_connect"
      expect(account.token).to match /^ey/
      expect(account.refresh_token).to match /^ey/

      auth.uid = "user@example.org"

      expect {
        OidcAccount.link(user, auth)
        account.reload
      }
        .to change { OidcAccount.count }.by(0)
        .and change { account.uid }
        .from("ofn@example.com").to("user@example.org")
    end
  end
end
