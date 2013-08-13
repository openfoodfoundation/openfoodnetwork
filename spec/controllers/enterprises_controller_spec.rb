require 'spec_helper'

describe EnterprisesController do
  it "displays suppliers" do
    s = create(:supplier_enterprise)
    d = create(:distributor_enterprise)

    spree_get :suppliers

    assigns(:suppliers).should == [s]
  end
end
