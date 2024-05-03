# frozen_string_literal: true

require 'spec_helper'
require 'open_food_network/i18n_config'

module OpenFoodNetwork
  describe I18nConfig do
    before do
      # Allow non-stubbed calls to ENV to proceed
      allow(ENV).to receive(:[]).and_call_original
    end

    context "in default test configuration" do
      before do
        allow(ENV).to receive(:[]).with("LOCALE").and_return("en")
        allow(ENV).to receive(:[]).with("AVAILABLE_LOCALES").and_return("en,es")
      end

      it "provides the source locale" do
        expect(I18nConfig.source_locale).to eq "en"
      end

      it "provides the default locale" do
        expect(I18nConfig.default_locale).to eq "en"
      end

      it "provides the default selectable locales" do
        expect(I18nConfig.selectable_locales).to eq ["en", "es"]
      end

      it "provides the default available locales" do
        expect(I18nConfig.available_locales).to eq ["en", "es"]
      end
    end

    context "without configuration" do
      before do
        allow(ENV).to receive(:[]).with("LOCALE").and_return(nil)
        allow(ENV).to receive(:[]).with("I18N_LOCALE").and_return(nil)
        allow(ENV).to receive(:[]).with("AVAILABLE_LOCALES").and_return(nil)
      end

      it "provides the source locale" do
        expect(I18nConfig.source_locale).to eq "en"
      end

      it "provides the default locale" do
        expect(I18nConfig.default_locale).to eq "en"
      end

      it "provides the default selectable locales" do
        expect(I18nConfig.selectable_locales).to eq []
      end

      it "provides the default available locales" do
        expect(I18nConfig.available_locales).to eq ["en"]
      end
    end

    context "with UK configuration" do
      before do
        allow(ENV).to receive(:[]).with("LOCALE").and_return("en_GB")
        allow(ENV).to receive(:[]).with("I18N_LOCALE").and_return(nil)
        allow(ENV).to receive(:[]).with("AVAILABLE_LOCALES").and_return("en_GB")
      end

      it "provides the source locale" do
        expect(I18nConfig.source_locale).to eq "en"
      end

      it "provides the default locale" do
        expect(I18nConfig.default_locale).to eq "en_GB"
      end

      it "provides the default selectable locales" do
        expect(I18nConfig.selectable_locales).to eq ["en_GB"]
      end

      it "provides the default available locales" do
        expect(I18nConfig.available_locales).to eq ["en_GB", "en"]
      end
    end

    context "with human syntax" do
      before do
        allow(ENV).to receive(:[]).with("LOCALE").and_return("es")
        allow(ENV).to receive(:[]).with("AVAILABLE_LOCALES").and_return("es, fr ,, ,de")
      end

      it "provides the default selectable locales" do
        expect(I18nConfig.selectable_locales).to eq ["es", "fr", "de"]
      end

      it "provides the default available locales" do
        expect(I18nConfig.available_locales).to eq ["es", "fr", "de", "en"]
      end
    end
  end
end
