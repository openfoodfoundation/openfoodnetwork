# frozen_string_literal: true

require 'spec_helper'

describe Spree::Core::ProductDuplicator do
  let(:product) do
    double 'Product',
           name: "foo",
           taxons: [],
           product_properties: [property],
           master: variant,
           variants?: false
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
    double 'Variant',
           sku: "12345",
           price: 19.99,
           currency: "AUD",
           images: [image]
  end

  let(:new_variant) do
    double 'New Variant',
           sku: "12345"
  end

  let(:image) do
    double 'Image',
           attachment: double('Attachment')
  end

  let(:new_image) do
    double 'New Image'
  end

  before do
    expect(product).to receive(:dup).and_return(new_product)
    expect(variant).to receive(:dup).and_return(new_variant)
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
    expect(new_product).to receive(:master=).with(new_variant)

    expect(new_variant).to receive(:sku=).with("COPY OF 12345")
    expect(new_variant).to receive(:deleted_at=).with(nil)
    expect(new_variant).to receive(:images=).with([new_image])
    expect(new_variant).to receive(:price=).with(variant.price)
    expect(new_variant).to receive(:currency=).with(variant.currency)

    expect(image.attachment).to receive(:clone).and_return(image.attachment)

    expect(new_image).to receive(:assign_attributes).
      with(attachment: image.attachment).
      and_return(new_image)

    expect(new_property).to receive(:created_at=).with(nil)
    expect(new_property).to receive(:updated_at=).with(nil)

    duplicator.duplicate
  end
end
