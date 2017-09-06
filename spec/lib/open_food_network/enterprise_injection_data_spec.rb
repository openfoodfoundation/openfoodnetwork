require 'spec_helper'

module OpenFoodNetwork
  describe EnterpriseInjectionData do
    describe "relatives" do
      let!(:enterprise) { create(:distributor_enterprise) }
      let!(:producer) { create(:supplier_enterprise) }

      it "loads self where appropiate" do
        subject.relatives[producer.id][:producers].should include producer.id
        subject.relatives[enterprise.id][:distributors].should include enterprise.id
      end
    end
  end
end
