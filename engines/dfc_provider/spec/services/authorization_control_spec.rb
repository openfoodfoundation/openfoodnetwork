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

  def auth(oidc_token:)
    described_class.new(
      double(:request,
             headers: { "Authorization" => "Bearer #{oidc_token}" },
             env: { 'warden' => nil })
    )
  end
end
