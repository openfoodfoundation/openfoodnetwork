# frozen_string_literal: true

RSpec.describe Spree::Taxon do
  let(:taxon) { described_class.new(name: "Ruby on Rails") }

  let(:e) { create(:supplier_enterprise) }
  let(:e2) { create(:supplier_enterprise) }
  let(:t1) { create(:taxon) }
  let(:t2) { create(:taxon) }

  describe ".supplied_taxons" do
    let!(:p1) {
      create(:simple_product, primary_taxon_id: t1.id, enterprise_id: e.id)
    }
    let!(:p2) {
      create(:simple_product, primary_taxon_id: t2.id, enterprise_id: e2.id)
    }

    context "when scoped to specific enterprises" do
      it "finds taxons" do
        expect(described_class.supplied_taxons([e.id])).to eq(e.id => Set.new([t1.id]))
        expect(described_class.supplied_taxons([e2.id])).to eq(e2.id => Set.new([t2.id]))
        expect(described_class.supplied_taxons([e.id, e2.id])).to eq(
          e.id => Set.new([t1.id]),
          e2.id => Set.new([t2.id])
        )
      end
    end

    context "when not scoped to specific enterprises" do
      it "finds taxons" do
        expect(described_class.supplied_taxons).to eq(
          e.id => Set.new([t1.id]),
          e2.id => Set.new([t2.id])
        )
      end
    end
  end

  describe ".distributed_taxons" do
    before do
      [e, e2].each do |ent|
        p_open = create(:simple_product, primary_taxon: t1)
        p_closed = create(:simple_product, primary_taxon: t2)
        create(:open_order_cycle, distributors: [ent], variants: [p_open.variants.first])
        create(:closed_order_cycle, distributors: [ent], variants: [p_closed.variants.first])
      end
    end

    context "when scoped to specific enterprises" do
      it "finds all distributed taxons" do
        expect(described_class.distributed_taxons(:all, [e.id])).to eq(
          e.id => Set.new([t1.id, t2.id])
        )
        expect(described_class.distributed_taxons(:all, [e2.id])).to eq(
          e2.id => Set.new([t1.id, t2.id])
        )
        expect(described_class.distributed_taxons(:all, [e.id, e2.id])).to eq(
          e.id => Set.new([t1.id, t2.id]),
          e2.id => Set.new([t1.id, t2.id]),
        )
      end

      it "finds currently distributed taxons" do
        expect(described_class.distributed_taxons(:current, [e.id])).to eq(
          e.id => Set.new([t1.id])
        )
        expect(described_class.distributed_taxons(:current, [e2.id])).to eq(
          e2.id => Set.new([t1.id])
        )
        expect(described_class.distributed_taxons(:current, [e.id, e2.id])).to eq(
          e.id => Set.new([t1.id]),
          e2.id => Set.new([t1.id]),
        )
      end
    end

    context "when not scoped to specific enterprises" do
      it "finds all distributed taxons" do
        expect(described_class.distributed_taxons(:all)).to eq(
          e.id => Set.new([t1.id, t2.id]),
          e2.id => Set.new([t1.id, t2.id]),
        )
      end

      it "finds currently distributed taxons" do
        expect(described_class.distributed_taxons(:current)).to eq(
          e.id => Set.new([t1.id]),
          e2.id => Set.new([t1.id]),
        )
      end
    end
  end

  describe "touches" do
    let!(:taxon1) { create(:taxon) }
    let!(:taxon2) { create(:taxon) }
    let!(:product) { create(:simple_product, primary_taxon_id: taxon1.id) }
    let(:variant) { product.variants.first }

    it "is touched when assignment of primary_taxon on a variant changes" do
      expect do
        variant.update(primary_taxon: taxon2)
      end.to change { taxon2.reload.updated_at }
    end
  end

  describe "#name_i18n=" do
    it "merges into the existing hash instead of replacing it" do
      taxon = create(:taxon, name: "Fruit")
      taxon.update_column(:name_i18n, { "en_TST" => "Fruit" })

      # Simulates an admin update that only submits the currently selectable
      # locales, which may not include every locale already stored (e.g. a
      # locale removed from AVAILABLE_LOCALES, or a default locale that isn't
      # itself selectable).
      taxon.update(name_i18n: { "es" => "Fruta" })

      expect(taxon.reload.name_i18n).to eq({ "en_TST" => "Fruit", "es" => "Fruta" })
    end

    it "overwrites a locale's translation when it is resubmitted" do
      taxon = create(:taxon, name: "Fruit")
      taxon.update_column(:name_i18n, { "en" => "Fruit", "es" => "Fruta vieja" })

      taxon.update(name_i18n: { "es" => "Fruta" })

      expect(taxon.reload.name_i18n).to eq({ "en" => "Fruit", "es" => "Fruta" })
    end
  end

  describe "name_i18n column" do
    let(:taxon) { create(:taxon, name: "Vegetables") }

    it "defaults to an empty hash for an unsaved record" do
      new_taxon = described_class.new
      expect(new_taxon.name_i18n).to eq({})
    end

    it "allows storing translations per locale" do
      taxon.update_column(:name_i18n, { "en" => "Vegetables", "es" => "Verduras" })
      expect(taxon.reload.name_i18n).to eq({ "en" => "Vegetables", "es" => "Verduras" })
    end

    it "still exposes the original name column via read_attribute" do
      expect(taxon.read_attribute(:name)).to eq("Vegetables")
    end

    context "after backfilling name_i18n from the legacy name column" do
      before do
        taxon.update_column(:name_i18n, { I18n.default_locale.to_s => taxon.name })
      end

      it "has a non-empty name_i18n hash" do
        expect(taxon.reload.name_i18n).not_to be_empty
      end

      it "stores the legacy name under the default locale" do
        expect(taxon.name_i18n[I18n.default_locale.to_s]).to eq("Vegetables")
      end
    end
  end

  describe "#name" do
    let(:taxon) { create(:taxon, name: "Vegetables") }

    context "when the current locale has a translation" do
      it "returns the translation for the current locale" do
        taxon.update_column(:name_i18n, { "en" => "Vegetables", "es" => "Verduras" })
        I18n.with_locale(:es) do
          expect(taxon.reload.name).to eq("Verduras")
        end
      end
    end

    context "when the current locale is missing but default locale is present" do
      it "falls back to the default locale" do
        taxon.update_column(:name_i18n, { "en" => "Vegetables" })
        I18n.with_locale(:es) do
          expect(taxon.reload.name).to eq("Vegetables")
        end
      end
    end

    context "when both current and default locales are missing" do
      it "falls back to the first available translation" do
        taxon.update_column(:name_i18n, { "eu" => "Barazkiak" })
        I18n.with_locale(:es) do
          expect(taxon.reload.name).to eq("Barazkiak")
        end
      end
    end

    context "when name_i18n is completely empty" do
      it "falls back to the legacy name column" do
        taxon.update_column(:name_i18n, {})
        expect(taxon.reload.name).to eq("Vegetables")
      end
    end

    context "when the default locale translation is blank but another locale is filled" do
      it "falls back to the first present translation instead of the blank one" do
        taxon.update_column(:name_i18n, { "en" => "", "es" => "Verduras" })
        I18n.with_locale(:en) do
          expect(taxon.reload.name).to eq("Verduras")
        end
      end
    end
  end

  describe "#name=" do
    it "writes into name_i18n keyed by the current locale" do
      I18n.with_locale(:es) do
        taxon = described_class.new(name: "Verduras")
        expect(taxon.name_i18n).to eq({ "es" => "Verduras" })
      end
    end
  end

  describe "#sync_legacy_name_column" do
    context "when the default locale translation is blank but another locale is filled" do
      it "populates the legacy name column with the first present translation" do
        taxon = described_class.new(name_i18n: { "en" => "", "es" => "Verduras" })
        taxon.valid?
        expect(taxon.read_attribute(:name)).to eq("Verduras")
      end
    end
  end

  describe "validations" do
    it "is invalid when name_i18n is empty" do
      taxon = described_class.new
      expect(taxon).not_to be_valid
      expect(taxon.errors[:name_i18n]).to include("can't be blank")
    end
  end
end
