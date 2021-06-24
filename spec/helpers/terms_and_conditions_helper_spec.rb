# frozen_string_literal: true

require 'spec_helper'

describe TermsAndConditionsHelper, type: :helper do
  describe "#platform_terms_required?" do
    it "returns true" do
      expect(Spree::Config).to receive(:shoppers_require_tos).and_return(true)
      expect(helper.platform_terms_required?).to eq true
    end

    it "returns false" do
      expect(Spree::Config).to receive(:shoppers_require_tos).and_return(false)
      expect(helper.platform_terms_required?).to eq false
    end
  end
end
