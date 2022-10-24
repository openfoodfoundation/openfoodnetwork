# frozen_string_literal: true

require 'spec_helper'

describe Spree::Core::ProductDuplicator do
  let(:product) do
    double 'Product',
           name: "foo",
           taxons: [],
           product_properties: [property],
           master: master_variant,
           variants: [variant],
           option_types: []
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

  let(:master_variant) do
    double 'Variant',
           sku: "12345",
           price: 19.99,
           currency: "AUD",
           images: [image]
  end

  let(:variant) do
    double 'Variant 1',
           sku: "67890",
           price: 19.50,
           currency: "AUD",
           images: [image_variant]
  end

  let(:new_master_variant) do
    double 'New Variant',
           sku: "12345"
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
    expect(master_variant).to receive(:dup).and_return(new_master_variant)
    expect(image).to receive(:dup).and_return(new_image)
    expect(property).to receive(:dup).and_return(new_property)
  end

  it "can duplicate a product" do
    duplicator = Spree::Core::ProductDuplicator.new(product)
    expect(new_product).to receive(:name=).with("COPY OF foo")
    expect(new_product).to receive(:taxons=).with([])
    expect(new_product).to receive(:product_properties=).with([new_property])
    expect(new_product).to receive(:created_at=).with(nil)
    expect(new_product).to receive(:updated_at=).with(nil)
    expect(new_product).to receive(:deleted_at=).with(nil)
    expect(new_product).to receive(:master=).with(new_master_variant)
    expect(new_product).to receive(:option_types=).with([])

    expect(new_master_variant).to receive(:sku=).with("")
    expect(new_master_variant).to receive(:deleted_at=).with(nil)
    expect(new_master_variant).to receive(:images=).with([new_image])
    expect(new_master_variant).to receive(:price=).with(master_variant.price)
    expect(new_master_variant).to receive(:currency=).with(master_variant.currency)

    expect(image).to receive(:attachment_blob)
    expect(new_image).to receive_message_chain(:attachment, :attach)

    expect(new_property).to receive(:created_at=).with(nil)
    expect(new_property).to receive(:updated_at=).with(nil)

    duplicator.duplicate
  end
end
