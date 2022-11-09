# frozen_string_literal: true

require 'spec_helper'

describe DfcProvider::AuthorizationControl do
  let(:user) { create(:user) }

  describe "with OIDC token" do
    it "finds a user" do
      token = JWT.encode({ email: user.email }, nil)
      auth = described_class.new(
        double(:request,
               headers: { "Authorization" => "Bearer #{token}" })
      )

      expect(auth.user).to eq user
    end
  end
end
