require 'spec_helper'

describe EnterpriseRelationship do
  describe "scopes" do
    it "sorts by parent, child enterprise name" do
      e1 = create(:enterprise, name: 'A')
      e2 = create(:enterprise, name: 'B')
      e3 = create(:enterprise, name: 'C')
      er1 = create(:enterprise_relationship, parent: e1, child: e3)
      er2 = create(:enterprise_relationship, parent: e2, child: e1)
      er3 = create(:enterprise_relationship, parent: e1, child: e2)

      EnterpriseRelationship.by_name.should == [er3, er1, er2]
    end
  end
end
