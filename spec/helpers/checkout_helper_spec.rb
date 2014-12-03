require 'spec_helper'


describe CheckoutHelper do
  it "generates html for validated inputs" do
    helper.should_receive(:render).with(
      "shared/validated_input",
      name: "test",
      path: "foo",
      attributes: {:required=>true, :type=>:email, :name=>"foo", :id=>"foo", "ng-model"=>"foo", "ng-class"=>"{error: !fieldValid('foo')}"}
    )

    helper.validated_input("test", "foo", type: :email)
  end
end
