# frozen_string_literal: true

require 'rails_helper'

describe TermsOfServiceFile do
  describe ".current" do
    it "returns nil" do
      expect(TermsOfServiceFile.current).to be_nil
    end

    it "returns the last one" do
      existing = [
        TermsOfServiceFile.create!,
        TermsOfServiceFile.create!,
      ]

      expect(TermsOfServiceFile.current).to eq existing.last
    end
  end
end
