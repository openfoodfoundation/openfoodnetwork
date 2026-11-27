# frozen_string_literal: true

RSpec.describe Checkout::Params do
  let(:distributor) { create(:distributor_enterprise) }
  let(:order) { create(:order, distributor:) }
  let(:pickup) { create(:shipping_method, require_ship_address: false) }
  let(:delivery) { create(:shipping_method, require_ship_address: true) }
  let(:bill_address) { { firstname: "Ada", lastname: "Lovelace", phone: "0123456789" } }

  def build_params(order_params, shipping_method)
    ActionController::Parameters.new(
      order: order_params, shipping_method_id: shipping_method.id
    )
  end

  describe "#call" do
    context "with a pickup shipping method" do
      it "copies the name and phone from the billing address to the pickup address" do
        params = build_params({ bill_address_attributes: bill_address }, pickup)

        Checkout::Params.new(order, params, nil).call

        expect(order.ship_address.firstname).to eq "Ada"
        expect(order.ship_address.lastname).to eq "Lovelace"
        expect(order.ship_address.phone).to eq "0123456789"
      end

      it "doesn't raise when billing address attributes are missing" do
        params = build_params({ email: "ada@example.com" }, pickup)

        result = nil
        expect { result = Checkout::Params.new(order, params, nil).call }.not_to raise_error

        expect(result.to_h).to eq("email" => "ada@example.com")
        expect(order.ship_address.address1).to eq distributor.address.address1
      end

      it "ignores a submitted ship address when billing address attributes are missing" do
        params = build_params(
          { email: "ada@example.com", ship_address_attributes: { address1: "1 Elsewhere St" } },
          pickup
        )

        result = Checkout::Params.new(order, params, nil).call

        expect(result.to_h).not_to have_key("ship_address_attributes")
        expect(order.ship_address.address1).to eq distributor.address.address1
      end
    end

    context "with a shipping method that requires a shipping address" do
      it "doesn't raise when billing address attributes are missing" do
        params = build_params({ email: "ada@example.com" }, delivery)

        expect { Checkout::Params.new(order, params, nil).call }.not_to raise_error
      end
    end
  end
end
