# frozen_string_literal: true

require 'rails_helper'

describe TermsOfServiceFile do
  let(:pdf) { File.open(Rails.root.join("public/Terms-of-service.pdf")) }

  describe ".current" do
    it "returns nil" do
      expect(TermsOfServiceFile.current).to be_nil
    end

    it "returns the last one" do
      existing = [
        TermsOfServiceFile.create!(attachment: pdf),
        TermsOfServiceFile.create!(attachment: pdf),
      ]

      expect(TermsOfServiceFile.current).to eq existing.last
    end
  end
end
