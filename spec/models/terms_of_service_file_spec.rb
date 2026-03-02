# frozen_string_literal: true

RSpec.describe TermsOfServiceFile do
  include FileHelper

  let(:upload) { terms_pdf_file }

  describe ".current" do
    it "returns nil" do
      expect(TermsOfServiceFile.current).to be_nil
    end

    it "returns the last one" do
      existing = [
        TermsOfServiceFile.create!(attachment: upload),
        TermsOfServiceFile.create!(attachment: upload),
      ]

      expect(TermsOfServiceFile.current).to eq existing.last
    end
  end

  describe ".current_url" do
    let(:subject) { TermsOfServiceFile.current_url }

    it "points to nil if not ToS file is present" do
      expect(subject).to eq nil
    end

    it "points to a stored file" do
      file = TermsOfServiceFile.create!(attachment: upload)

      expect(subject).to match /active_storage.*Terms-of-service\.pdf$/
    end
  end

  describe ".updated_at" do
    let(:subject) { TermsOfServiceFile.updated_at }

    it "gives the most conservative time if not known" do
      freeze_time do
        expect(subject).to eq Time.zone.now
      end
    end

    it "returns the time when the terms were last updated" do
      update_time = 1.day.ago
      file = TermsOfServiceFile.create!(attachment: upload)
      file.update(updated_at: update_time)

      # The database isn't as precise as Ruby's time and rounds.
      expect(subject).to be_within(0.001).of(update_time)
    end
  end
end
