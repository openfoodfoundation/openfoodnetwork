describe Api::Admin::ForOrderCycle::EnterpriseSerializer do
  let(:enterprise)       { create(:distributor_enterprise) }
  let!(:product)         { create(:simple_product, supplier: enterprise) }
  let!(:deleted_product) { create(:simple_product, supplier: enterprise, deleted_at: Time.now) }
  let(:serialized_enterprise) { Api::Admin::ForOrderCycle::EnterpriseSerializer.new(enterprise, spree_current_user: enterprise.owner ).to_json }

  describe "supplied products" do
    it "does not render deleted products" do
      expect(serialized_enterprise).to have_json_size(1).at_path 'supplied_products'
      expect(serialized_enterprise).to be_json_eql(product.master.id).at_path 'supplied_products/0/master_id'
    end
  end
end
