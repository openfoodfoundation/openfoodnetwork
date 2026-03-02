# frozen_string_literal: true

RSpec.describe Spree::Core::ProductDuplicator do
  describe "unit" do
    let(:product) do
      instance_double(
        Spree::Product,
        name: "foo",
        product_properties: [property],
        variants: [variant],
        image:,
        variant_unit: 'item'
      )
    end
    let(:new_product) { instance_double(Spree::Product, save!: true) }
    let(:property) { instance_double(Spree::ProductProperty) }
    let(:new_property) { instance_double(Spree::ProductProperty) }
    let(:variant) do
      instance_double(
        Spree::Variant, sku: "67890", price: 19.50, currency: "AUD", images: [image_variant]
      )
    end
    let(:new_variant) { instance_double(Spree::Variant, sku: "67890") }
    let(:image) { instance_double(Spree::Image, attachment: double('Attachment')) }
    let(:new_image) { instance_double(Spree::Image) }
    let(:image_variant) { instance_double(Spree::Image, attachment: double('Attachment')) }
    let(:new_image_variant) { instance_double(Spree::Image, attachment: double('Attachment')) }

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
      # Name has a max length of 255 char, when cloning a product the cloned product has a name
      # starting with "COPY OF <product.name>". So we set a name with 254 char to make sure the
      # cloned product will be invalid
      let(:product) {
        create(:product).tap{ |v| v.update_columns(name: "l" * 254) }
      }

      subject { Spree::Core::ProductDuplicator.new(product).duplicate }

      it "raises RecordInvalid error" do
        expect{ subject }.to raise_error(ActiveRecord::ActiveRecordError)
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
