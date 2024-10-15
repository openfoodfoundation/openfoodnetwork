# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe SuppliedProductBuilder do
  include FileHelper

  subject(:builder) { described_class }
  let(:variant) {
    create(:variant, id: 5, product: spree_product, primary_taxon: taxon, supplier:)
  }
  let(:spree_product) {
    create(:product, id: 6)
  }
  let(:supplier) {
    create(:supplier_enterprise, id: 7)
  }
  let(:taxon) {
    build(
      :taxon,
      name: "Soft Drink",
      dfc_id: "https://github.com/datafoodconsortium/taxonomies/releases/latest/download/productTypes.rdf#soft-drink"
    )
  }

  describe ".supplied_product" do
    it "assigns a semantic id" do
      product = builder.supplied_product(variant)

      expect(product.semanticId).to eq(
        "http://test.host/api/dfc/enterprises/7/supplied_products/5"
      )
    end

    it "assigns a quantity" do
      product = builder.supplied_product(variant)

      expect(product.quantity.value).to eq 1.0
      expect(product.quantity.unit.semanticId).to eq "dfc-m:Gram"
    end

    it "assigns the product name by default" do
      variant.product.name = "Apple"
      product = builder.supplied_product(variant)

      expect(product.name).to match /Apple/
    end

    it "assigns the variant name if present" do
      variant.product.name = "Apple"
      variant.display_name = "Granny Smith"
      product = builder.supplied_product(variant)

      expect(product.name).to match /Apple - Granny Smith/
    end

    context "product_type mapping" do
      subject(:product) { builder.supplied_product(variant) }

      it "assigns a product type" do
        soft_drink = DfcLoader.connector.PRODUCT_TYPES.DRINK.SOFT_DRINK

        expect(product.productType).to eq soft_drink
      end
    end

    it "assigns an image_url type" do
      Spree::Image.create!(
        attachment: white_logo_file,
        viewable_id: variant.product.id,
        viewable_type: 'Spree::Product'
      )
      product = builder.supplied_product(variant)

      expect(product.image).to eq variant.product.image.url(:product)
    end

    it "assigns the product uri" do
      product = builder.supplied_product(variant)

      expect(product.spree_product_uri).to eq(
        "http://test.host/api/dfc/enterprises/7?spree_product_id=6"
      )
    end
  end

  describe ".store_product" do
    let(:subject) { builder.store_product(product, supplier) }
    let(:product) {
      DfcIo.import(product_json).find do |subject|
        subject.is_a? DataFoodConsortium::Connector::SuppliedProduct
      end
    }
    let(:product_json) { ExampleJson.read("product.GET") }

    before do
      taxon.save!
    end

    it "stores a new Spree Product and Variant" do
      expect { subject }.to change {
        Spree::Product.count
      }.by(1)

      expect(subject).to be_a(Spree::Variant)
      expect(subject).to be_valid
      expect(subject).to be_persisted
      expect(subject.name).to eq("Fillet Steak - 201g x 1 Steak")
      expect(subject.variant_unit).to eq("items")
      expect(subject.variant_unit_scale).to eq(nil)
      expect(subject.variant_unit_with_scale).to eq("items")
      expect(subject.unit_value).to eq(1)
    end
  end

  describe ".update_product" do
    let(:subject) { builder.update_product(product, variant) }
    let(:product) {
      DfcIo.import(product_json).find do |subject|
        subject.is_a? DataFoodConsortium::Connector::SuppliedProduct
      end
    }
    let(:product_json) { ExampleJson.read("product.GET") }

    it "updates a variant" do
      variant # Create test data first

      expect { subject }.not_to change {
        Spree::Variant.count
      }

      expect(subject).to eq variant
      expect(subject.display_name).to eq "Fillet Steak - 201g x 1 Steak"
      expect(subject.variant_unit).to eq "items"
      expect(subject.unit_value).to eq 1
      expect(subject.on_demand).to eq false
      expect(subject.on_hand).to eq 11
    end
  end

  describe ".import_product" do
    let(:supplied_product) do
      DfcProvider::SuppliedProduct.new(
        "https://example.net/tomato",
        name: "Tomato",
        description: "Awesome tomato",
        quantity: DataFoodConsortium::Connector::QuantitativeValue.new(
          unit: DfcLoader.connector.MEASURES.KILOGRAM,
          value: 2,
        ),
        productType: product_type,
        image: "https://cd.net/tomato.png?v=5",
      )
    end
    let(:product_type) { DfcLoader.connector.PRODUCT_TYPES.VEGETABLE.NON_LOCAL_VEGETABLE }
    let!(:taxon) {
      create(
        :taxon,
        name: "Non local vegetable",
        dfc_id: "https://github.com/datafoodconsortium/taxonomies/releases/latest/download/productTypes.rdf#non-local-vegetable"
      )
    }

    before do
      stub_request(:get, "https://cd.net/tomato.png?v=5").to_return(
        status: 200,
        body: black_logo_path.read,
      )
    end

    it "creates a new Spree::Product" do
      product = builder.import_product(supplied_product, supplier)

      expect(product).to be_a(Spree::Product)
      expect(product.name).to eq("Tomato")
      expect(product.description).to eq("Awesome tomato")
      expect(product.variant_unit).to eq("weight")
      expect(product.image).to be_present
      expect(product.image.attachment).to be_attached
      expect(product.image.url(:product)).to match /^http.*tomato\.png/
    end

    describe "taxon" do
      it "assigns the taxon matching the DFC product type" do
        product = builder.import_product(supplied_product, supplier)

        expect(product.variants.first.primary_taxon).to eq(taxon)
      end
    end
  end

  describe ".import_variant" do
    let(:imported_variant) { builder.import_variant(supplied_product, supplier) }
    let(:supplied_product) do
      DfcProvider::SuppliedProduct.new(
        "https://example.net/tomato",
        name: "Tomato",
        description: "Awesome tomato",
        quantity: DataFoodConsortium::Connector::QuantitativeValue.new(
          unit: DfcLoader.connector.MEASURES.KILOGRAM,
          value: 2,
        ),
        productType: product_type,
        catalogItems: [catalog_item],
      )
    end
    let(:product_type) { DfcLoader.connector.PRODUCT_TYPES.VEGETABLE.NON_LOCAL_VEGETABLE }
    let(:catalog_item) {
      DataFoodConsortium::Connector::CatalogItem.new(
        nil,
        # On-demand is expressed as negative stock.
        # And some APIs send strings instead of numbers...
        stockLimitation: "-1",
        offers: [offer],
      )
    }
    let(:offer) {
      DataFoodConsortium::Connector::Offer.new(
        nil,
        price: DataFoodConsortium::Connector::Price.new(value: "15.50"),
      )
    }

    it "creates a new Spree::Product and variant" do
      # We need this to save stock:
      DefaultStockLocation.find_or_create

      create(:taxon)

      expect(imported_variant).to be_a(Spree::Variant)
      expect(imported_variant).to be_valid
      expect(imported_variant.id).to be_nil
      expect(imported_variant.semantic_links.size).to eq 1

      link = imported_variant.semantic_links[0]
      expect(link.semantic_id).to eq "https://example.net/tomato"

      imported_product = imported_variant.product
      expect(imported_product).to be_a(Spree::Product)
      expect(imported_product).to be_valid
      expect(imported_product.id).to be_nil
      expect(imported_product.name).to eq("Tomato")
      expect(imported_product.description).to eq("Awesome tomato")
      expect(imported_product.variant_unit).to eq("weight")

      # Stock can only be checked when persisted:
      imported_product.save!
      expect(imported_variant.price).to eq 15.50
      expect(imported_variant.on_demand).to eq true
      expect(imported_variant.on_hand).to eq 0
    end

    context "with spree_product_id supplied" do
      let(:imported_variant) { builder.import_variant(supplied_product, supplier) }

      let(:supplied_product) do
        DfcProvider::SuppliedProduct.new(
          "https://example.net/tomato",
          name: "Tomato",
          description: "Better Awesome tomato",
          quantity: DataFoodConsortium::Connector::QuantitativeValue.new(
            unit: DfcLoader.connector.MEASURES.KILOGRAM,
            value: 2,
          ),
          productType: product_type,
          spree_product_id: variant.product.id
        )
      end
      let(:product_type) { DfcLoader.connector.PRODUCT_TYPES.DRINK.SOFT_DRINK.FRUIT_JUICE }
      let!(:new_taxon) {
        create(
          :taxon,
          name: "Fruit Juice",
          dfc_id: "https://github.com/datafoodconsortium/taxonomies/releases/latest/download/productTypes.rdf#fruit-juice"
        )
      }

      it "update an existing Spree::Product" do
        imported_product = imported_variant.product
        expect(imported_product.id).to eq(spree_product.id)
        expect(imported_product.description).to eq("Better Awesome tomato")
        expect(imported_variant.primary_taxon).to eq(new_taxon)
      end

      context "when spree_product_uri doesn't match the server host" do
        let(:supplied_product) do
          DfcProvider::SuppliedProduct.new(
            "https://example.net/tomato",
            name: "Tomato",
            description: "Awesome tomato",
            quantity: DataFoodConsortium::Connector::QuantitativeValue.new(
              unit: DfcLoader.connector.MEASURES.KILOGRAM,
              value: 2,
            ),
            productType: product_type,
            spree_product_uri: "http://another.host/api/dfc/enterprises/10/supplied_products/50"
          )
        end

        it "creates a new Spree::Product and variant" do
          expect(imported_variant).to be_a(Spree::Variant)
          expect(imported_variant.id).to be_nil

          imported_product = imported_variant.product
          expect(imported_product).to be_a(Spree::Product)
          expect(imported_product.id).to be_nil
          expect(imported_product.name).to eq("Tomato")
          expect(imported_product.description).to eq("Awesome tomato")
          expect(imported_product.variant_unit).to eq("weight")
        end
      end
    end
  end

  describe ".referenced_spree_product" do
    let(:result) { builder.referenced_spree_product(supplied_product, supplier) }
    let(:supplied_product) do
      DfcProvider::SuppliedProduct.new(
        "https://example.net/tomato",
        name: "Tomato",
      )
    end

    it "returns nil when no reference is given" do
      expect(result).to eq nil
    end

    it "returns a product referenced by URI" do
      variant.save!
      supplied_product.spree_product_uri =
        "http://test.host/api/dfc/enterprises/7?spree_product_id=6"
      expect(result).to eq spree_product
    end

    it "doesn't return a product of another enterprise" do
      variant.save!
      create(:product, id: 8, supplier_id: create(:enterprise).id)

      supplied_product.spree_product_uri =
        "http://test.host/api/dfc/enterprises/7?spree_product_id=8"
      expect(result).to eq nil
    end

    it "doesn't return a foreign product referenced by URI" do
      variant.save!
      supplied_product.spree_product_uri =
        "http://another.host/api/dfc/enterprises/7?spree_product_id=6"
      expect(result).to eq nil
    end

    it "returns a product referenced by id" do
      variant.save!
      supplied_product.spree_product_id = "6"
      expect(result).to eq spree_product
    end
  end
end
