# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe AuthorizationControl do
  include AuthorizationHelper

  let(:user) { create(:oidc_user) }

  describe "with OIDC token" do
    it "accepts a token from Les Communs" do
      user.oidc_account.update!(uid: "testdfc@protonmail.com")
      lc_token = file_fixture("les_communs_access_token.jwt").read

      travel_to(Date.parse("2025-06-13")) do
        expect(auth(oidc_token: lc_token).user).to eq user
      end
    end

    it "accepts a token from Startin'Blox" do
      sib_token = file_fixture("startinblox_access_token.jwt").read

      travel_to(Date.parse("2025-06-13")) do
        expect(auth(oidc_token: sib_token).user.id).to eq "cqcm-dev"
      end
    end

    it "accepts a token from FDC" do
      sib_token = file_fixture("fdc_access_token.jwt").read

      travel_to(Date.parse("2025-06-13")) do
        expect(auth(oidc_token: sib_token).user.id).to eq "lf-dev"
      end
    end

    it "finds the right user" do
      create(:oidc_user) # another user
      token = allow_token_for(email: user.email)

      expect(auth(oidc_token: token).user).to eq user
    end

    it "ignores blank email" do
      OidcAccount.where(user:).update_all(uid: "")
      token = allow_token_for(email: "")

      expect(auth(oidc_token: token).user).to eq nil
    end

    it "ignores non-existent user" do
      user
      token = allow_token_for(email: generate(:random_email))

      expect(auth(oidc_token: token).user).to eq nil
    end

    it "ignores expired signatures" do
      token = allow_token_for(exp: Time.now.to_i, email: user.email)

      expect(auth(oidc_token: token).user).to eq nil
    end

    it "ignores malformed tokens" do
      token = "eyJhbGciOiJSUzI1NiIsInR5c"

      expect(auth(oidc_token: token).user).to eq nil
    end
  end

  describe "with OFN API token" do
    it "finds the user of the API key" do
      user.update!(spree_api_key: "1234")

      expect(auth(api_token: "1234").user).to eq user
    end

    it "returns nil if the token doesn't match" do
      user.update!(spree_api_key: "1234")

      expect(auth(api_token: "123").user).to eq nil
    end

    it "ignores a missing token" do
      user.update!(spree_api_key: nil)

      expect(auth(api_token: nil).user).to eq nil
    end

    it "ignores empty tokens" do
      user.update!(spree_api_key: "")

      expect(auth(api_token: "").user).to eq nil
    end
  end

  def auth(oidc_token: nil, api_token: nil)
    headers = {}
    headers["Authorization"] = "Bearer #{oidc_token}" if oidc_token
    headers["X-Api-Token"] = api_token if api_token

    described_class.new(
      double(:request, headers:, env: { 'warden' => nil })
    )
  end
end
