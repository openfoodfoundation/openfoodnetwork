# frozen_string_literal: true

require_relative '../../db/migrate/20260826022154_sanitize_product_description'

RSpec.describe SanitizeProductDescription do
  describe "#up" do
    let!(:product_nil_desc) { create(:simple_product, description: nil) }
    let!(:product_empty_desc) { create(:simple_product, description: "") }
    let!(:product_normal) { create(:simple_product, description: normal_desc) }
    let!(:product_bad) {
      # The attribute is sanitised at assignment. So we need to inject into the
      # database differently:
      create(:simple_product).tap do |product|
        product.update_columns(description: bad_desc)
      end
    }
    let!(:product_leading_blank) {
      create(:simple_product).tap do |product|
        product.update_columns(description: leading_blank_desc)
      end
    }

    let(:normal_desc) { "<p>Fresh, organic apples picked this morning.</p>" }
    let(:bad_desc) {
      '<p data-controller="load->payMe">Fresh apples ' \
        '<script>alert("Gotcha!")</script>...</p>'
    }
    let(:bad_desc_sanitised) { '<p>Fresh apples alert("Gotcha!")...</p>' }
    let(:leading_blank_desc) {
      "<div><br></div><div>Real product description.</div>"
    }
    let(:leading_blank_desc_sanitised) { "<div>Real product description.</div>" }

    it "sanitises product descriptions and strips leading empty blocks" do
      expect { subject.up }.to change {
        product_bad.reload.attributes["description"]
      }.from(bad_desc).to(bad_desc_sanitised)

      expect(product_nil_desc.reload.description).to eq nil
      expect(product_empty_desc.reload.description).to eq ""
      expect(product_normal.reload.attributes["description"]).to eq normal_desc
      expect(product_leading_blank.reload.attributes["description"])
        .to eq leading_blank_desc_sanitised
    end
  end
end
