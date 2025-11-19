# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe ApiUser do
  subject(:user) { described_class.new("cqcm-dev") }

  describe ".from_client_id" do
    it "finds by URI" do
      uri = "https://api.proxy-dev.cqcm.startinblox.com/profile"
      user = ApiUser.from_client_id(uri)
      expect(user.id).to eq "cqcm-dev"
    end

    it "finds by short id" do
      uri = "lf-dev"
      user = ApiUser.from_client_id(uri)
      expect(user.id).to eq "lf-dev"
    end
  end

  describe "#customers" do
    it "returns nothing" do
      expect(user.customers).to be_empty
    end
  end
end
