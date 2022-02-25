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
end
