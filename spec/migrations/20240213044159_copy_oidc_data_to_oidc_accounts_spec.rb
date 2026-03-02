# frozen_string_literal: true


require_relative '../../db/migrate/20240213044159_copy_oidc_data_to_oidc_accounts'

RSpec.describe CopyOidcDataToOidcAccounts do
  describe "up" do
    let!(:user) { create(:user) }
    let!(:oidc_user) {
      create(:user, provider: "openid_connect", uid: "ofn@example.net")
    }

    it "copies data" do
      expect { subject.up }.to change {
        OidcAccount.count
      }.from(0).to(1)

      account = OidcAccount.first

      expect(account.user).to eq oidc_user
      expect(account.provider).to eq oidc_user.provider
      expect(account.uid).to eq oidc_user.uid
      expect(account.token).to eq nil
    end
  end

  describe "down" do
    it "removes data" do
      user = create(:user)
      OidcAccount.create!(user:, provider: "oidc", uid: "ofn@exmpl.net")

      expect { subject.down }.to change { OidcAccount.count }.from(1).to(0)
    end
  end
end
