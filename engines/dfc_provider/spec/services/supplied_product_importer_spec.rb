# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe SuppliedProductImporter do
  include FileHelper

  subject(:importer) { described_class }
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

  describe ".store_product" do
    let(:subject) { importer.store_product(product, supplier) }
    let(:product) {
      DfcIo.import(product_json).find do |subject|
        subject.is_a? DataFoodConsortium::Connector::SuppliedProduct
      end
    }
    let(:product_json) { ExampleJson.read("product.GET") }

    before do
      taxon.save!

      stub_request(:get, "https://cd.net/tomato.png?v=5").to_return(
        status: 200,
        body: black_logo_path.read
      )
      allow(product).to receive(:image).and_return("https://cd.net/tomato.png?v=5")
    end

    it "stores a new Spree Product and Variant with image" do
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

      expect(subject.product.image).to be_present
      expect(subject.product.image.attachment).to be_attached
      expect(subject.product.image.url(:product)).to match(/^http.*tomato\.png/)
    end
  end

  describe ".update_product" do
    let(:subject) { importer.update_product(product, variant) }
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

    it "builds an unsaved Spree::Product with all mapped attributes" do
      product = importer.import_product(supplied_product, supplier)

      expect(product).to be_a(Spree::Product)
      expect(product.name).to eq("Tomato")
      expect(product.description).to eq("Awesome tomato")
      expect(product.variant_unit).to eq("weight")
      expect(product.image).to be_present
      expect(product.image.attachment).to be_attached
    end

    describe "taxon" do
      it "assigns the taxon matching the DFC product type" do
        product = importer.import_product(supplied_product, supplier)

        expect(product.variants.first.primary_taxon).to eq(taxon)
      end
    end
  end

  describe ".import_variant" do
    let(:imported_variant) { importer.import_variant(supplied_product, supplier) }
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

    context "linked to product group" do
      let(:imported_variant) { importer.import_variant(supplied_product, supplier) }

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

      it "copies name and description from parent product" do
        supplied_product.isVariantOf << DfcProvider::SuppliedProduct.new(
          "some-id", name: "Our tomatoes", description: "Choose a variety."
        )
        imported_product = imported_variant.product
        expect(imported_product.name).to eq "Our tomatoes"
        expect(imported_product.description).to eq "Choose a variety."
      end

      it "updates images when their URL changes" do
        stub_request(:get, "https://cd.net/tomato.png?v=1").to_return(
          status: 200, body: black_logo_path.read,
        )
        stub_request(:get, "https://cd.net/tomato.png?v=2").to_return(
          status: 200, body: white_logo_path.read,
        )

        tomatoes = DfcProvider::SuppliedProduct.new(
          "some-id", name: "Tomatoes",
                     image: "https://cd.net/tomato.png?v=1",
        )
        supplied_product.isVariantOf << tomatoes

        imported_product = importer.import_variant(supplied_product, supplier).product
        expect(imported_product.image.attachment.filename).to eq "tomato.png"

        expect {
          importer.import_variant(supplied_product, supplier).product
          imported_product.reload
        }
          .not_to change { imported_product.image }

        expect {
          tomatoes.image = "https://cd.net/tomato.png?v=2"
          importer.import_variant(supplied_product, supplier).product
          imported_product.reload
        }
          .to change { imported_product.image }

        expect(imported_product.image.attachment.filename).to eq "tomato.png"
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
            spree_product_uri: "http://another.host/api/dfc/enterprises/10/supplied_products/50",
            isVariantOf: [product_group],
          )
        end
        let(:product_group) do
          DataFoodConsortium::Connector::SuppliedProduct.new(
            "http://test.host/api/dfc/product_groups/6"
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
          expect(imported_product.semantic_link.semantic_id)
            .to eq "http://test.host/api/dfc/product_groups/6"
        end
      end
    end
  end

  describe ".referenced_spree_product" do
    let(:result) { importer.referenced_spree_product(supplied_product, supplier) }
    let(:supplied_product) do
      DfcProvider::SuppliedProduct.new(
        "https://example.net/tomato",
        name: "Tomato",
      )
    end

    it "returns nil when no reference is given" do
      expect(result).to eq nil
    end

    it "returns a product referenced by semantic id" do
      variant.save!
      supplied_product.isVariantOf <<
        DataFoodConsortium::Connector::SuppliedProduct.new(
          "http://test.host/api/dfc/product_groups/6"
        )
      expect(result).to eq spree_product
    end

    it "returns a product referenced by external URI" do
      variant.save!
      supplied_product.isVariantOf <<
        DataFoodConsortium::Connector::SuppliedProduct.new(
          "http://example.net/product_group"
        )
      SemanticLink.create!(
        subject: spree_product,
        semantic_id: "http://example.net/product_group",
      )
      expect(result).to eq spree_product
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
