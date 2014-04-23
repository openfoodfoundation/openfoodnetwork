require 'spec_helper'


describe CheckoutHelper do
  it "generates html for validated inputs" do
    helper.should_receive(:render).with(
      partial: "shared/validated_input",
      locals: {name: "test", path: "foo", required: true, type: :email}
    )
  
    helper.validated_input("test", "foo", type: :email)
  end
end
