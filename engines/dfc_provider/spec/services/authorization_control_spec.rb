# frozen_string_literal: true

require DfcProvider::Engine.root.join("spec/spec_helper")

describe AuthorizationControl do
  include AuthorizationHelper

  let(:user) { create(:oidc_user) }

  describe "with OIDC token" do
    it "finds the right user" do
      create(:oidc_user) # another user
      token = allow_token_for(email: user.email)

      expect(auth(oidc_token: token).user).to eq user
    end

    it "ignores blank email" do
      create(:user, uid: nil)
      create(:user, uid: "")
      token = allow_token_for(email: nil)

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
