require 'spec_helper'

module OpenFoodNetwork
  describe EnterpriseInjectionData do
    describe "relatives" do
      let!(:enterprise) { create(:distributor_enterprise) }
      let!(:producer) { create(:supplier_enterprise) }
      let!(:producer_inactive) { create(:supplier_enterprise, sells: 'unspecified') }
      let!(:er_p)  { create(:enterprise_relationship, parent: producer, child: enterprise) }
      let!(:er_pi) { create(:enterprise_relationship, parent: producer_inactive, child: enterprise) }

      it "only loads activated relatives" do
        expect(subject.relatives[enterprise.id][:producers]).not_to include producer_inactive.id
      end

      it "loads self where appropiate" do
        expect(subject.relatives[producer.id][:producers]).to include producer.id
        expect(subject.relatives[enterprise.id][:distributors]).to include enterprise.id
      end
    end
  end
end
