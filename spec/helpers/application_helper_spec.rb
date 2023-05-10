# frozen_string_literal: true

require 'spec_helper'

describe ApplicationHelper, type: :helper do
  describe "#language_meta_tags" do
    let(:request) { double("request", host_with_port: "test.host", protocol: "http://") }
    before do
      allow(helper).to receive(:request).and_return(request)
    end

    context "when there is more than one available locale" do
      before do
        allow(I18n).to receive(:available_locales) { ["en", "es", "pt"] }
      end

      it "displays a language tag for each available locale" do
        expect(language_meta_tags).to include('<link hreflang="en" href="http://test.host/locales/en">')
        expect(language_meta_tags).to include('<link hreflang="es" href="http://test.host/locales/es">')
        expect(language_meta_tags).to include('<link hreflang="pt" href="http://test.host/locales/pt">')
      end
    end

    context "when there is only one available locale" do
      before do
        allow(I18n).to receive(:available_locales) { ["en"] }
      end

      it "doesn't include any language tags" do
        expect(language_meta_tags).to be_nil
      end
    end

    context "when the availables locales have regional variations" do
      before do
        allow(I18n).to receive(:available_locales) { ["fr_CA", "en_CA"] }
      end

      it "includes the region code in the :hreflang attribute" do
        expect(language_meta_tags).to include('<link hreflang="fr-ca" href="http://test.host/locales/fr_CA">')
        expect(language_meta_tags).to include('<link hreflang="en-ca" href="http://test.host/locales/en_CA">')
      end
    end
  end

  describe "#cache_with_locale" do
    let(:available_locales) { ["en", "es"] }
    let(:current_locale) { "es" }
    let(:locale_digest) { "8a7s5dfy28u0as9du" }
    let(:options) { { expires_in: 10.seconds } }

    before do
      allow(I18n).to receive(:available_locales) { available_locales }
      allow(I18n).to receive(:locale) { current_locale }
      allow(I18nDigests).to receive(:for_locale) { locale_digest }
    end

    it "passes key, options, and block to #cache method with locale and locale digest appended" do
      expect(helper).to receive(:cache_key_with_locale).
        with("test-key", current_locale).and_return(["test-key", current_locale, locale_digest])

      expect(helper).to receive(:cache).
        with(["test-key", current_locale, locale_digest], options) do |&block|
          expect(block.call).to eq("cached content")
        end

      helper.cache_with_locale "test-key", options do
        "cached content"
      end
    end
  end

  describe "#cache_key_with_locale" do
    let(:en_digest) { "asd689asy0239" }
    let(:es_digest) { "9d8tu23oirhad" }

    before { allow(I18nDigests).to receive(:for_locale).with("en") { en_digest } }
    before { allow(I18nDigests).to receive(:for_locale).with("es") { es_digest } }

    it "appends locale and digest to a single key" do
      expect(
        helper.cache_key_with_locale("single-key", "en")
      ).to eq(["single-key", "en", en_digest])
    end

    it "appends locale and digest to multiple keys" do
      expect(
        helper.cache_key_with_locale(["array", "of", "keys"], "es")
      ).to eq(["array", "of", "keys", "es", es_digest])
    end
  end
end
