# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe ApiUser do
  subject(:user) { described_class.new("cqcm-dev") }

  describe "#customers" do
    it "returns nothing" do
      expect(user.customers).to be_empty
    end
  end
end
