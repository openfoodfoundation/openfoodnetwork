# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Spree::Core::ProductDuplicator do
  describe "unit" do
    let(:product) do
      double 'Product',
             name: "foo",
             product_properties: [property],
             variants: [variant],
             image:,
             variant_unit: 'item'
    end

    let(:new_product) do
      double 'New Product',
             save!: true
    end

    let(:property) do
      double 'Property'
    end

    let(:new_property) do
      double 'New Property'
    end

    let(:variant) do
      double 'Variant 1',
             sku: "67890",
             price: 19.50,
             currency: "AUD",
             images: [image_variant]
    end

    let(:new_variant) do
      double 'New Variant 1',
             sku: "67890"
    end

    let(:image) do
      double 'Image',
             attachment: double('Attachment')
    end

    let(:new_image) do
      double 'New Image'
    end

    let(:image_variant) do
      double 'Image Variant',
             attachment: double('Attachment')
    end

    let(:new_image_variant) do
      double 'New Image Variant',
             attachment: double('Attachment')
    end

    before do
      expect(product).to receive(:dup).and_return(new_product)
      expect(variant).to receive(:dup).and_return(new_variant)
      expect(image).to receive(:dup).and_return(new_image)
      expect(image_variant).to receive(:dup).and_return(new_image_variant)
      expect(property).to receive(:dup).and_return(new_property)
    end

    it "can duplicate a product" do
      duplicator = Spree::Core::ProductDuplicator.new(product)
      expect(new_product).to receive(:name=).with("COPY OF foo")
      expect(new_product).to receive(:sku=).with("")
      expect(new_product).to receive(:product_properties=).with([new_property])
      expect(new_product).to receive(:created_at=).with(nil)
      expect(new_product).to receive(:price=).with(0)
      expect(new_product).to receive(:unit_value=).with(nil)
      expect(new_product).to receive(:updated_at=).with(nil)
      expect(new_product).to receive(:deleted_at=).with(nil)
      expect(new_product).to receive(:variants=).with([new_variant])
      expect(new_product).to receive(:image=).with(new_image)

      expect(new_variant).to receive(:sku=).with("")
      expect(new_variant).to receive(:deleted_at=).with(nil)
      expect(new_variant).to receive(:images=).with([new_image_variant])
      expect(new_variant).to receive(:price=).with(variant.price)
      expect(new_variant).to receive(:currency=).with(variant.currency)

      expect(image).to receive(:attachment_blob)
      expect(new_image).to receive_message_chain(:attachment, :attach)

      expect(image_variant).to receive(:attachment_blob)
      expect(new_image_variant).to receive_message_chain(:attachment, :attach)

      expect(new_property).to receive(:created_at=).with(nil)
      expect(new_property).to receive(:updated_at=).with(nil)

      duplicator.duplicate
    end
  end

  describe "errors" do
    context "with invalid product" do
      let(:product) {
        # name is a required field
        create(:product).tap{ |p| p.update_columns(variant_unit: nil) }
      }
      subject { Spree::Core::ProductDuplicator.new(product).duplicate }

      it "raises RecordInvalid error" do
        expect{ subject }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "invalid variant" do
      let(:variant) {
        # tax_category is required when products_require_tax_category
        create(:variant).tap{ |v| v.update_columns(tax_category_id: nil) }
      }
      subject { Spree::Core::ProductDuplicator.new(variant.product).duplicate }

      before { allow(Spree::Config).to receive(:products_require_tax_category).and_return(true) }

      it "raises generic ActiveRecordError" do
        expect{ subject }.to raise_error(ActiveRecord::ActiveRecordError)
      end
    end
  end
end
