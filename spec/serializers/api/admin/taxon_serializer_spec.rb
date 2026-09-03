# frozen_string_literal: true

RSpec.describe Api::Admin::TaxonSerializer do
  let(:taxon) { create(:taxon, name: "Vegetables") }
  let(:serializer) { described_class.new(taxon) }

  before do
    taxon.update_column(:name_i18n, { "en" => "Vegetables", "es" => "Verduras" })
  end

  it "serializes the taxon name in the current locale" do
    I18n.with_locale(:es) do
      expect(serializer.serializable_hash[:name]).to eq("Verduras")
    end
  end

  it "falls back to the default locale when the current locale is missing" do
    I18n.with_locale(:fr) do
      expect(serializer.serializable_hash[:name]).to eq("Vegetables")
    end
  end
end
