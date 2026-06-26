# frozen_string_literal: true

RSpec.describe Admin::ProductsHelper do
  describe '#unit_value_with_description' do
    let(:variant) {
      create(:variant, variant_unit_scale: 1000.0, unit_value: 2000.0, unit_description: 'kg')
    }

    context 'when unit_value and unit_description are present' do
      it 'returns the scaled unit value with the description' do
        expect(helper.unit_value_with_description(variant)).to eq('2 kg')
      end
    end

    context 'when unit_value is nil' do
      before { variant.update_column(:unit_value, nil) }

      it 'returns the description' do
        expect(helper.unit_value_with_description(variant)).to eq('kg')
      end
    end

    context 'when unit_description is nil' do
      before { variant.update_column(:unit_description, nil) }

      it 'returns only the scaled unit value' do
        expect(helper.unit_value_with_description(variant)).to eq('2')
      end
    end

    context 'when variant_unit_scale is nil' do
      before { variant.update_column(:variant_unit_scale, nil) }

      it 'uses default scale of 1 and returns the unscaled unit value with the description' do
        expect(helper.unit_value_with_description(variant)).to eq('2000 kg')
      end
    end

    context 'when both unit_value and unit_description are nil' do
      before { variant.update_columns(unit_description: nil, unit_value: nil) }

      it 'returns empty string' do
        expect(helper.unit_value_with_description(variant)).to eq('')
      end
    end
  end

  describe '#prepare_new_variant' do
    let(:zone) { create(:zone_with_member) }
    let(:product) {
      create(:taxed_product, zone:, price: 12.54, tax_rate_amount: 0,
                             included_in_price: true)
    }

    context 'when tax category is present for first varient' do
      it 'sets tax category for new variant' do
        first_variant_tax_id = product.variants.first.tax_category_id
        expect(helper.prepare_new_variant(product, []).tax_category_id).to eq(first_variant_tax_id)
      end
    end
  end

  describe "#variant_displayable?" do
    let(:supplier) { create(:supplier_enterprise) }
    let(:variant) { create(:variant, supplier: ) }
    let(:allowed_producers) { [supplier] }
    let(:allowed_source_producers) { [] }
    let(:managed_product_enterprises) { [] }

    before do
      allow(helper).to receive(:managed_product_enterprises).and_return(managed_product_enterprises)
    end

    it "returns true" do
      expect(helper.variant_displayable?(variant, allowed_producers,
                                         allowed_source_producers)).to eq(true)
    end

    context "with linked variant" do
      context "with the user's linked variant" do
        let(:hub) { create(:distributor_enterprise) }
        let(:source_supplier) { create(:supplier_enterprise) }
        let(:variant) { create(:variant, supplier: source_supplier, hub: hub) }
        let(:allowed_source_producers) { [source_supplier] }
        let(:managed_product_enterprises) { [supplier, hub] }

        it "returns true" do
          expect(helper.variant_displayable?(variant, allowed_producers,
                                             allowed_source_producers)).to eq(true)
        end
      end

      context "wiht someone else's linked variant" do
        let(:other_enterprise) { create(:supplier_enterprise) }
        let(:variant) { create(:variant, supplier:, hub: other_enterprise) }

        it "returns false" do
          expect(helper.variant_displayable?(variant, allowed_producers,
                                             allowed_source_producers)).to eq(false)
        end
      end
    end

    context "with a variant the user has permission to manage" do
      let(:friend_supplier) { create(:supplier_enterprise) }
      let(:variant) { create(:variant, supplier: friend_supplier) }
      let(:allowed_producers) { [supplier, friend_supplier] }

      it "returns true" do
        expect(helper.variant_displayable?(variant, allowed_producers,
                                           allowed_source_producers)).to eq(true)
      end
    end

    context "with a variant the user doesn't have permission manage" do
      let(:other_supplier) { create(:supplier_enterprise) }
      let(:variant) { create(:variant, supplier: other_supplier) }

      it "returns false" do
        expect(helper.variant_displayable?(variant, allowed_producers,
                                           allowed_source_producers)).to eq(false)
      end
    end

    context "with a variant with no supplier" do
      let(:variant) { build(:variant, supplier: nil) }

      it "returns true" do
        expect(helper.variant_displayable?(variant, allowed_producers,
                                           allowed_source_producers)).to eq(true)
      end
    end
  end

  describe "#variant_readonly?" do
    let(:supplier) { create(:supplier_enterprise) }
    let(:variant) { create(:variant, supplier: ) }
    let(:allowed_producers) { [supplier] }
    let(:allowed_source_producers) { [] }
    let(:friend_supplier) { create(:supplier_enterprise) }

    it "returns false" do
      expect(helper.variant_readonly?(variant, allowed_producers,
                                      allowed_source_producers)).to eq(false)
    end

    context "with linked variant" do
      let(:variant) { create(:variant, supplier: friend_supplier, hub: supplier) }
      let(:allowed_source_producers) { [friend_supplier] }

      it "returns false" do
        expect(helper.variant_readonly?(variant, allowed_producers,
                                        allowed_source_producers)).to eq(false)
      end
    end

    context "with variant the user has permission to create linked variants" do
      let(:variant) { create(:variant, supplier: friend_supplier) }
      let(:allowed_source_producers) { [friend_supplier] }

      it "returns true" do
        expect(helper.variant_readonly?(variant, allowed_producers,
                                        allowed_source_producers)).to eq(true)
      end
    end
  end
end
