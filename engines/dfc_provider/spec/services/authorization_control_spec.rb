# frozen_string_literal: true

require DfcProvider::Engine.root.join("spec/spec_helper")

describe DfcProvider::AuthorizationControl do
  include AuthorizationHelper

  let(:user) { create(:user) }

  describe "with OIDC token" do
    it "finds a user" do
      token = allow_token_for(email: user.email)

      expect(auth(token).user).to eq user
    end

    it "ignores expired signatures" do
      token = allow_token_for(exp: Time.now.to_i, email: user.email)

      expect(auth(token).user).to eq nil
    end
  end

  def auth(token)
    described_class.new(
      double(:request,
             headers: { "Authorization" => "Bearer #{token}" })
    )
  end
end
