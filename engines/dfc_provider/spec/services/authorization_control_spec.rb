# frozen_string_literal: true

require 'spec_helper'

describe DfcProvider::AuthorizationControl do
  let(:test_public_key) { "-----BEGIN PUBLIC KEY-----
MIGeMA0GCSqGSIb3DQEBAQUAA4GMADCBiAKBgFb9ARWvTPr3/I3rO7dx/83c0UGR
5A8nkvxAj3hsm23c0SFJLGxBfFTy+CcuGJWe2Yu6V+zxo0i3yeR99jjWUBPmyIol
FLHKjzLCaHNlTuY+N6CkQCtHVDLKHopfl/t3xZabuaqhPXA1SYb4Gm12DwMGznXY
X6yOmI+kVDBkhlL/AgMBAAE=
-----END PUBLIC KEY-----" }

  # token to encode the payload: { "email": "fredo.farmer@hub.com" }
  let(:valid_token) {
    "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6ImZyZWRvLmZhcm1lckBodWIuY29tIn0.TKxGbScx_zvZpWG40ikaXrp5PH2PDEtFSxeFHR2-VnmkezAQhvvVSEnMeiDbMmfKNwSNy2JLmL1ky7TuARq86RqwKYnjMX9HLDCUzq52VTG0ZK6uYX2J2PCibSzOLu5-67BkGwe5yglQaKrSvqtoAimSxetNqA59rCp6WXxxP8g"
  }
  let(:invalid_token) { "invalid" }

  describe "processing a valid token" do
    let(:user) { instance_double(Spree::User) }
    let(:authorization_control) { DfcProvider::AuthorizationControl.new(valid_token) }

    it "returns the correct OFN user" do
      allow(Spree::User).to receive(:where).with(email: "fredo.farmer@hub.com") { [user] }
      expect(authorization_control.process).to eq(user)
    end
  end

  describe "processing an invalid token" do
    let(:authorization_control) { DfcProvider::AuthorizationControl.new(invalid_token) }

    it "returns nil" do
      expect(authorization_control.process).to be nil
    end
  end
end
