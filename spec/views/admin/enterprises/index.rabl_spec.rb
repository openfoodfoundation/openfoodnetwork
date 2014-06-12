require 'spec_helper'

describe "admin/enterprises/index.rabl" do
  let(:enterprise)       { create(:distributor_enterprise) }
  let!(:product)         { create(:simple_product, supplier: enterprise) }
  let!(:deleted_product) { create(:simple_product, supplier: enterprise, deleted_at: 1.day.ago) }
  let(:render)           { Rabl.render([enterprise], 'admin/enterprises/index', view_path: 'app/views', scope: RablHelper::FakeContext.instance) }

  describe "supplied products" do
    it "does not render deleted products" do
      render.should have_json_size(1).at_path '0/supplied_products'
      render.should be_json_eql(product.master.id).at_path '0/supplied_products/0/master_id'
    end
  end
end
