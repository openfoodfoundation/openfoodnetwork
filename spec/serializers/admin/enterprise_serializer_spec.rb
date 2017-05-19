describe Api::Admin::EnterpriseSerializer do
  let(:enterprise) { create(:distributor_enterprise) }
  it "serializes an enterprise" do
    serializer = Api::Admin::EnterpriseSerializer.new enterprise 
    serializer.to_json.should match enterprise.name  
  end
end
