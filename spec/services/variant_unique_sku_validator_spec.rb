require "spec_helper"

# variants with the same unit_value, unit_description, display_name, and display_as.
describe VariantUniqueSkuValidator do
  let!(:product) do
    create(:product, sku: "PRODUCT_SKU", unit_value: 1.0, unit_description: "",
                     variant_unit: "weight", variant_unit_scale: 1.0)
  end

  let(:validator) { described_class.new(variant) }
  let(:master) { product.master }

  context "when SKU is non-blank" do
    let!(:existing_variant) { create(:variant, product: product, sku: "V0001") }

    it "allows SKU that is unique among product's variants" do
      variant = build(:variant, product: product, sku: "V0002")
      expect(variant.save).to be_truthy
    end

    it "does not allow SKU that is not unique among product's variants" do
      variant = build(:variant, product: product, sku: existing_variant.sku)
      expect(variant.save).to be_falsey
      expect(variant.errors[:sku]).to eq(["has already been taken"])
    end

    it "ignores deleted variant with same SKU" do
      existing_variant.destroy

      variant = build(:variant, product: product, sku: existing_variant.sku)
      expect(variant.save).to be_truthy
    end

    it "ignores master variant with same SKU" do
      # Make the SKU of the first variant different from that of the master variant.
      first_variant = product.variants.order(:id).first
      first_variant.update_attributes!(sku: "FIRST_VARIANT_SKU")

      variant = build(:variant, product: product, sku: master.sku)
      expect(variant.save).to be_truthy
    end
  end

  context "when SKU is blank" do
    let!(:existing_variant) { create(:variant, product: product, sku: "", unit_value: 1) }

    it "allows SKU if there is no lookalike variant of product that has blank SKU" do
      variant = build(:variant, product: product, sku: "", unit_value: 2)
      expect(variant.save).to be_truthy
    end

    it "does not allow SKU if there is a lookalike variant of product that has blank SKU" do
      variant = build(:variant, product: product, sku: "", unit_value: 1)
      expect(variant.save).to be_falsey
      expect(variant.errors[:sku]).to eq([error_message_if_has_lookalike_with_same_sku_error])
    end

    it "treats empty string and nil SKU as identical" do
      variant = build(:variant, product: product, sku: nil, unit_value: 1)
      expect(variant.save).to be_falsey
      expect(variant.errors[:sku]).to eq([error_message_if_has_lookalike_with_same_sku_error])

      variant.sku = ""
      expect(variant.save).to be_falsey
      expect(variant.errors[:sku]).to eq([error_message_if_has_lookalike_with_same_sku_error])
    end

    it "ignores deleted variant that has blank SKU" do
      existing_variant.destroy

      variant = build(:variant, product: product, sku: "", unit_value: 1)
      expect(variant.save).to be_truthy
    end

    it "ignores master variant that has blank SKU" do
      # Make the SKU of the first variant different from that of the master variant.
      first_variant = product.variants.order(:id).first
      first_variant.update_attributes!(sku: "FIRST_VARIANT_SKU")

      master.update_attributes!(sku: "", unit_value: 2)

      existing_variant.unit_value = master.unit_value
      existing_variant.unit_description = master.unit_description
      existing_variant.display_name = master.display_name
      existing_variant.display_as = master.display_as
      expect(existing_variant.save).to be_truthy
    end
  end

  context "when the variant is master variant" do
    it "does not require non-blank SKU to be unique among product's variants" do
      variant = create(:variant, product: product, sku: "V0001", unit_value: master.unit_value,
                                 unit_description: master.unit_description,
                                 display_name: master.display_name, display_as: master.display_as)

      master.sku = variant.sku
      expect(master.save).to be_truthy
    end

    it "allows blank SKU even if non-master variant of product already has blank SKU" do
      create(:variant, product: product, sku: "", unit_value: master.unit_value,
                       unit_description: master.unit_description, display_name: master.display_name,
                       display_as: master.display_as)

      master.sku = ""
      expect(master.save).to be_truthy
    end
  end

  def error_message_if_has_lookalike_with_same_sku_error
    I18n.t("activerecord.errors.models.spree/variant.attributes.sku.has_lookalike_with_same_sku")
  end
end
