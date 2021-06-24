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

  describe ".current_url" do
    let(:subject) { TermsOfServiceFile.current_url }

    it "points to the old default" do
      expect(subject).to eq "/Terms-of-service.pdf"
    end

    it "points to the last uploaded file with timestamp parameter" do
      file = TermsOfServiceFile.create!(attachment: pdf)

      expect(subject).to match %r{^/system/terms_of_service_files/attachments.*Terms-of-service\.pdf\?\d+$}
    end
  end

  describe ".updated_at" do
    let(:subject) { TermsOfServiceFile.updated_at }

    it "gives the most conservative time if not known" do
      Timecop.freeze do
        expect(subject).to eq Time.zone.now
      end
    end

    it "returns the time when the terms were last updated" do
      update_time = 1.day.ago
      file = TermsOfServiceFile.create!(attachment: pdf, updated_at: update_time)

      # The database isn't as precise as Ruby's time and rounds.
      expect(subject).to be_within(0.001).of(update_time)
    end
  end
end
