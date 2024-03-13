# frozen_string_literal: true

require "reflex_helper"

describe ProductsReflex, type: :reflex, feature: :admin_style_v3 do
  let(:current_user) { create(:admin_user) } # todo: set up an enterprise user to test permissions
  let(:context) {
    { url: admin_products_url, connection: { current_user: } }
  }
  let(:flash) { {} }

  before do
    # Mock flash, because stimulus_reflex_testing doesn't support sessions
    allow_any_instance_of(described_class).to receive(:flash).and_return(flash)
  end

  describe '#fetch' do
    subject { build_reflex(method_name: :fetch, **context) }

    describe "sorting" do
      let!(:product_z) { create(:simple_product, name: "Zucchini") }
      # let!(:product_b) { create(:simple_product, name: "bananas") } # Fails on macOS
      let!(:product_a) { create(:simple_product, name: "Apples") }

      it "Should sort products alphabetically by default" do
        subject.run(:fetch)

        expect(subject.get(:products).to_a).to eq [
          product_a,
          # product_b,
          product_z,
        ]
      end
    end
  end

  describe '#filter' do
    context "when filtering by category" do
      let!(:product_a) { create(:simple_product, name: "Apples") }
      let!(:product_z) do
        create(:simple_product, name: "Zucchini").tap do |p|
          p.variants.first.update(primary_taxon: category_c)
        end
      end
      let(:category_c) { create(:taxon, name: "Category 1") }

      it "returns product with a variant matching the given category" do
        # Add a second variant to test we are not returning duplicate product
        product_z.variants << create(:variant, primary_taxon: category_c)

        reflex = run_reflex(:filter, params: { category_id: category_c.id } )

        expect(reflex.get(:products).to_a).to eq([product_z])
      end
    end
  end

  describe '#bulk_update' do
    let!(:variant_a1) {
      product_a.variants.first.tap{ |v|
        v.update! display_name: "Medium box", sku: "APL-01", price: 5.25, on_hand: 5,
                  on_demand: false
      }
    }
    let!(:product_c) { create(:simple_product, name: "Carrots", sku: "CAR-00") }
    let!(:product_b) { create(:simple_product, name: "Bananas", sku: "BAN-00") }
    let!(:product_a) { create(:simple_product, name: "Apples", sku: "APL-00") }

    it "saves valid changes" do
      params = {
        # '[products][0][name]'
        "products" => {
          "0" => {
            "id" => product_a.id.to_s,
            "name" => "Pommes",
            "sku" => "POM-00",
          },
        },
      }

      expect{
        run_reflex(:bulk_update, params:)
        product_a.reload
      }.to change{ product_a.name }.to("Pommes")
        .and change{ product_a.sku }.to("POM-00")

      expect(flash).to include success: "Changes saved"
    end

    it "saves valid changes to products and nested variants" do
      # Form field names:
      #   '[products][0][id]' (hidden field)
      #   '[products][0][name]'
      #   '[products][0][variants_attributes][0][id]' (hidden field)
      #   '[products][0][variants_attributes][0][display_name]'
      params = {
        "products" => {
          "0" => {
            "id" => product_a.id.to_s,
            "name" => "Pommes",
            "variant_unit_with_scale" => "volume_0.001", # 1mL
            "variants_attributes" => {
              "0" => {
                "id" => variant_a1.id.to_s,
                "display_name" => "Large box",
                "sku" => "POM-01",
                "price" => "10.25",
                "on_hand" => "6",
              },
            },
          },
        },
      }

      expect{
        run_reflex(:bulk_update, params:)
        product_a.reload
        variant_a1.reload
      }.to change{ product_a.name }.to("Pommes")
        .and change{ product_a.variant_unit }.to("volume")
        .and change{ product_a.variant_unit_scale }.to(0.001)
        .and change{ variant_a1.display_name }.to("Large box")
        .and change{ variant_a1.sku }.to("POM-01")
        .and change{ variant_a1.price }.to(10.25)
        .and change{ variant_a1.on_hand }.to(6)

      expect(flash).to include success: "Changes saved"
    end

    it "creates new variants" do
      # Form field names:
      #   '[products][0][id]' (hidden field)
      #   '[products][0][name]'
      #   '[products][0][variants_attributes][0][id]' (hidden field)
      #   '[products][0][variants_attributes][0][display_name]'
      #   '[products][0][variants_attributes][1][display_name]' (id is omitted for new record)
      #   '[products][0][variants_attributes][2][display_name]' (more than 1 new record is allowed)
      params = {
        "products" => {
          "0" => {
            "id" => product_a.id.to_s,
            "name" => "Pommes",
            "variants_attributes" => {
              "0" => {
                "id" => variant_a1.id.to_s,
                "display_name" => "Large box",
              },
              "1" => {
                "display_name" => "Small box",
                "sku" => "POM-02",
                "price" => "5.25",
                "unit_value" => "0.5",
              },
              "2" => {
                "sku" => "POM-03",
                "price" => "15.25",
                "unit_value" => "2",
              },
            },
          },
        },
      }

      expect{
        run_reflex(:bulk_update, params:)
        product_a.reload
        variant_a1.reload
      }.to change{ product_a.name }.to("Pommes")
        .and change{ variant_a1.display_name }.to("Large box")
        .and change{ product_a.variants.count }.by(2)

      variant_a2 = product_a.variants[1]
      expect(variant_a2.display_name).to eq "Small box"
      expect(variant_a2.sku).to eq "POM-02"
      expect(variant_a2.price).to eq 5.25
      expect(variant_a2.unit_value).to eq 0.5

      variant_a3 = product_a.variants[2]
      expect(variant_a3.display_name).to be_nil
      expect(variant_a3.sku).to eq "POM-03"
      expect(variant_a3.price).to eq 15.25
      expect(variant_a3.unit_value).to eq 2

      expect(flash).to include success: "Changes saved"
    end

    describe "sorting" do
      let(:params) {
        {
          "products" => {
            "0" => {
              "id" => product_a.id.to_s,
              "name" => "Pommes",
            },
            "1" => {
              "id" => product_b.id.to_s,
            },
          },
        }
      }
      subject{ run_reflex(:bulk_update, params:) }

      it "Should retain sort order, even when names change" do
        expect(subject.get(:products).map(&:id)).to eq [
          product_a.id,
          product_b.id,
        ]
        expect(flash).to include success: "Changes saved"
      end
    end

    describe "error messages" do
      it "summarises error messages" do
        params = {
          "products" => {
            "0" => {
              "id" => product_a.id.to_s,
              "name" => "Pommes",
            },
            "1" => {
              "id" => product_b.id.to_s,
              "name" => "", # Name can't be blank
            },
            "2" => {
              "id" => product_c.id.to_s,
              "name" => "", # Name can't be blank
            },
          },
        }

        reflex = run_reflex(:bulk_update, params:)
        expect(reflex.get(:error_counts)).to eq({ saved: 1, invalid: 2 })
        expect(flash).not_to include success: "Changes saved"

        # # WTF
        # expect{ reflex(:bulk_update, params:) }.to broadcast(
        #   replace: {
        #     selector: "#products-form",
        #     html: /2 products have errors/,
        #   },
        #   broadcast: nil
        # )
      end
    end
  end

  describe '#delete_product' do
    let(:product) { create(:simple_product) }
    let(:action_name) { :delete_product }

    subject { build_reflex(method_name: action_name, **context) }

    before { subject.element.dataset.current_id = product.id }

    context 'given that the current user is admin' do
      let(:current_user) { create(:admin_user) }

      it 'should successfully delete the product' do
        subject.run(action_name)
        product.reload
        expect(product.deleted_at).not_to be_nil
        expect(flash[:success]).to eq('Successfully deleted the product')
      end

      it 'should be failed to delete the product' do
        # mock db query failure
        allow_any_instance_of(Spree::Product).to receive(:destroy).and_return(false)
        subject.run(action_name)
        product.reload
        expect(product.deleted_at).to be_nil
        expect(flash[:error]).to eq('Unable to delete the product')
      end
    end

    context 'given that the current user is not admin' do
      let(:current_user) { create(:user) }

      it 'should raise the access denied exception' do
        expect { subject.run(action_name) }.to raise_exception(CanCan::AccessDenied)
      end
    end
  end

  describe '#delete_variant' do
    let(:variant) { create(:variant) }
    let(:action_name) { :delete_variant }

    subject { build_reflex(method_name: action_name, **context) }

    before { subject.element.dataset.current_id = variant.id }

    context 'given that the current user is admin' do
      let(:current_user) { create(:admin_user) }

      it 'should successfully delete the variant' do
        subject.run(action_name)
        variant.reload
        expect(variant.deleted_at).not_to be_nil
        expect(flash[:success]).to eq('Successfully deleted the variant')
      end

      it 'should be failed to delete the product' do
        # mock db query failure
        allow_any_instance_of(Spree::Variant).to receive(:destroy).and_return(false)
        subject.run(action_name)
        variant.reload
        expect(variant.deleted_at).to be_nil
        expect(flash[:error]).to eq('Unable to delete the variant')
      end
    end

    context 'given that the current user is not admin' do
      let(:current_user) { create(:user) }

      it 'should raise the access denied exception' do
        expect { subject.run(action_name) }.to raise_exception(CanCan::AccessDenied)
      end
    end
  end
end

# Build and run a reflex using the context
# Parameters can be added with params: option
# For more options see https://github.com/podia/stimulus_reflex_testing#usage
def run_reflex(method_name, opts = {})
  build_reflex(method_name:, **context.merge(opts)).tap{ |reflex|
    reflex.run(method_name)
  }
end
