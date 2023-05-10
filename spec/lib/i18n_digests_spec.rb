# frozen_string_literal: true

require 'spec_helper'

describe I18nDigests do
  describe "#build_digests" do
    let(:available_locales) { ["en", "es"] }
    let(:md5_hex_regex) { /([a-f0-9]){10}/ }

    around do |example|
      original = Rails.application.config.x.i18n_digests
      example.run
      Rails.application.config.x.i18n_digests = original
    end

    it "computes and stores digests for each locale file" do
      Rails.application.config.x.i18n_digests = {}
      I18nDigests.build_digests(available_locales)

      expect(Rails.application.config.x.i18n_digests.keys).to eq [:en, :es]
      expect(Rails.application.config.x.i18n_digests.values).to all match(md5_hex_regex)

      expect(
        Rails.application.config.x.i18n_digests[:en]
      ).to eq(Digest::MD5.hexdigest(Rails.root.join("config/locales/en.yml").read))

      expect(
        Rails.application.config.x.i18n_digests[:es]
      ).to eq(Digest::MD5.hexdigest(Rails.root.join("config/locales/es.yml").read))
    end
  end

  describe "#for_locale" do
    let(:digests) { { en: "as8d7a9sdh", es: "iausyd9asdh" } }

    before do
      allow(Rails).to receive_message_chain(:application, :config, :x, :i18n_digests) { digests }
    end

    it "returns the digest for a given locale" do
      expect(I18nDigests.for_locale("en")).to eq "as8d7a9sdh"
    end
  end
end
