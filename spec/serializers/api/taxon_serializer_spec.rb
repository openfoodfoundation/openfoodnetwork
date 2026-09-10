# frozen_string_literal: true

RSpec.describe Api::TaxonSerializer do
  let(:taxon) { create(:taxon, name: "Vegetables") }
  let(:serializer) { described_class.new(taxon) }

  before do
    taxon.update_column(:name_i18n, {
                          I18n.default_locale.to_s => "Vegetables",
                          "es" => "Verduras"
                        })
  end

  it "serializes the taxon name in the current locale without cache leaking" do
    I18n.with_locale(:es) do
      expect(serializer.serializable_hash[:name]).to eq("Verduras")
    end

    I18n.with_locale(:fr) do
      expect(serializer.serializable_hash[:name]).to eq("Vegetables")
    end
  end
end
