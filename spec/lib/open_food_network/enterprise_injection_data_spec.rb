require 'spec_helper'

module OpenFoodNetwork
  describe EnterpriseInjectionData do
    describe "relatives" do
      let!(:enterprise) { create(:distributor_enterprise) }
      let!(:producer) { create(:supplier_enterprise) }
      let!(:producer_inactive) { create(:supplier_enterprise, confirmed_at: nil) }
      let!(:er_p)  { create(:enterprise_relationship, parent: producer, child: enterprise) }
      let!(:er_pi) { create(:enterprise_relationship, parent: producer_inactive, child: enterprise) }

      it "only loads activated relatives" do
        subject.relatives[enterprise.id][:producers].should_not include producer_inactive.id
      end
    end
  end
end
