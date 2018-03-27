describe Api::Admin::EnterpriseSerializer do
  let(:enterprise) { create(:distributor_enterprise) }
  it "serializes an enterprise" do
    serializer = Api::Admin::EnterpriseSerializer.new enterprise 
    expect(serializer.to_json).to match enterprise.name  
  end
end
