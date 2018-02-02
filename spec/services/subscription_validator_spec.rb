describe StandingOrderValidator do
  let(:shop) { instance_double(Enterprise, name: "Shop") }

  describe "delegation" do
    let(:standing_order) { create(:standing_order) }
    let(:validator) { StandingOrderValidator.new(standing_order) }

    it "delegates to standing_order" do
      expect(validator.shop).to eq standing_order.shop
      expect(validator.customer).to eq standing_order.customer
      expect(validator.schedule).to eq standing_order.schedule
      expect(validator.shipping_method).to eq standing_order.shipping_method
      expect(validator.payment_method).to eq standing_order.payment_method
      expect(validator.bill_address).to eq standing_order.bill_address
      expect(validator.ship_address).to eq standing_order.ship_address
      expect(validator.begins_at).to eq standing_order.begins_at
      expect(validator.ends_at).to eq standing_order.ends_at
    end
  end

  describe "validations" do
    let(:standing_order_stubs) do
      {
        shop: shop,
        customer: true,
        schedule: true,
        shipping_method: true,
        payment_method: true,
        bill_address: true,
        ship_address: true,
        begins_at: true,
        ends_at: true,
        credit_card: true
      }
    end

    let(:validation_stubs) do
      {
        shipping_method_allowed?: true,
        payment_method_allowed?: true,
        payment_method_type_allowed?: true,
        ends_at_after_begins_at?: true,
        customer_allowed?: true,
        schedule_allowed?: true,
        credit_card_ok?: true,
        standing_line_items_present?: true,
        requested_variants_available?: true
      }
    end

    let(:standing_order) { instance_double(StandingOrder, standing_order_stubs) }
    let(:validator) { StandingOrderValidator.new(standing_order) }

    def stub_validations(validator, methods)
      methods.each do |name, value|
        allow(validator).to receive(name) { value }
      end
    end

    describe "shipping method validation" do
      let(:standing_order) { instance_double(StandingOrder, standing_order_stubs.except(:shipping_method)) }
      before { stub_validations(validator, validation_stubs.except(:shipping_method_allowed?)) }

      context "when no shipping method is present" do
        before { expect(standing_order).to receive(:shipping_method).at_least(:once) { nil } }

        it "adds an error and returns false" do
          expect(validator.valid?).to be false
          expect(validator.errors[:shipping_method]).to_not be_empty
        end
      end

      context "when a shipping method is present" do
        let(:shipping_method) { instance_double(Spree::ShippingMethod, distributors: [shop]) }
        before { expect(standing_order).to receive(:shipping_method).at_least(:once) { shipping_method } }

        context "and the shipping method is not associated with the shop" do
          before { allow(shipping_method).to receive(:distributors) { [double(:enterprise)] } }

          it "adds an error and returns false" do
            expect(validator.valid?).to be false
            expect(validator.errors[:shipping_method]).to_not be_empty
          end
        end

        context "and the shipping method is associated with the shop" do
          before { allow(shipping_method).to receive(:distributors) { [shop] } }

          it "returns true" do
            expect(validator.valid?).to be true
            expect(validator.errors[:shipping_method]).to be_empty
          end
        end
      end
    end

    describe "payment method validation" do
      let(:standing_order) { instance_double(StandingOrder, standing_order_stubs.except(:payment_method)) }
      before { stub_validations(validator, validation_stubs.except(:payment_method_allowed?)) }

      context "when no payment method is present" do
        before { expect(standing_order).to receive(:payment_method).at_least(:once) { nil } }

        it "adds an error and returns false" do
          expect(validator.valid?).to be false
          expect(validator.errors[:payment_method]).to_not be_empty
        end
      end

      context "when a payment method is present" do
        let(:payment_method) { instance_double(Spree::PaymentMethod, distributors: [shop]) }
        before { expect(standing_order).to receive(:payment_method).at_least(:once) { payment_method } }

        context "and the payment method is not associated with the shop" do
          before { allow(payment_method).to receive(:distributors) { [double(:enterprise)] } }

          it "adds an error and returns false" do
            expect(validator.valid?).to be false
            expect(validator.errors[:payment_method]).to_not be_empty
          end
        end

        context "and the payment method is associated with the shop" do
          before { allow(payment_method).to receive(:distributors) { [shop] } }

          it "returns true" do
            expect(validator.valid?).to be true
            expect(validator.errors[:payment_method]).to be_empty
          end
        end
      end
    end

    describe "payment method type validation" do
      let(:standing_order) { instance_double(StandingOrder, standing_order_stubs.except(:payment_method)) }
      before { stub_validations(validator, validation_stubs.except(:payment_method_type_allowed?)) }

      context "when a payment method is present" do
        let(:payment_method) { instance_double(Spree::PaymentMethod, distributors: [shop]) }
        before { expect(standing_order).to receive(:payment_method).at_least(:once) { payment_method } }

        context "and the payment method type is not in the approved list" do
          before { allow(payment_method).to receive(:type) { "Blah" } }

          it "adds an error and returns false" do
            expect(validator.valid?).to be false
            expect(validator.errors[:payment_method]).to_not be_empty
          end
        end

        context "and the payment method is in the approved list" do
          let(:approved_type) { StandingOrder::ALLOWED_PAYMENT_METHOD_TYPES.first }
          before { allow(payment_method).to receive(:type) { approved_type } }

          it "returns true" do
            expect(validator.valid?).to be true
            expect(validator.errors[:payment_method]).to be_empty
          end
        end
      end
    end

    describe "dates" do
      let(:standing_order) { instance_double(StandingOrder, standing_order_stubs.except(:begins_at, :ends_at)) }
      before { stub_validations(validator, validation_stubs.except(:ends_at_after_begins_at?)) }
      before { expect(standing_order).to receive(:begins_at).at_least(:once) { begins_at } }

      context "when no begins_at is present" do
        let(:begins_at) { nil }

        it "adds an error and returns false" do
          expect(validator.valid?).to be false
          expect(validator.errors[:begins_at]).to_not be_empty
        end
      end

      context "when a start date is present" do
        let(:begins_at) { Time.zone.today }
        before { expect(standing_order).to receive(:ends_at).at_least(:once) { ends_at } }

        context "when no ends_at is present" do
          let(:ends_at) { nil }

          it "returns true" do
            expect(validator.valid?).to be true
            expect(validator.errors[:ends_at]).to be_empty
          end
        end

        context "when ends_at is equal to begins_at" do
          let(:ends_at) { Time.zone.today }
          it "adds an error and returns false" do
            expect(validator.valid?).to be false
            expect(validator.errors[:ends_at]).to_not be_empty
          end
        end

        context "when ends_at is before begins_at" do
          let(:ends_at) { Time.zone.today - 1.day }
          it "adds an error and returns false" do
            expect(validator.valid?).to be false
            expect(validator.errors[:ends_at]).to_not be_empty
          end
        end

        context "when ends_at is after begins_at" do
          let(:ends_at) { Time.zone.today + 1.day }
          it "adds an error and returns false" do
            expect(validator.valid?).to be true
            expect(validator.errors[:ends_at]).to be_empty
          end
        end
      end
    end

    describe "addresses" do
      before { stub_validations(validator, validation_stubs) }
      let(:standing_order) { instance_double(StandingOrder, standing_order_stubs.except(:bill_address, :ship_address)) }
      before { expect(standing_order).to receive(:bill_address).at_least(:once) { bill_address } }
      before { expect(standing_order).to receive(:ship_address).at_least(:once) { ship_address } }

      context "when bill_address and ship_address are not present" do
        let(:bill_address) { nil }
        let(:ship_address) { nil }

        it "adds an error and returns false" do
          expect(validator.valid?).to be false
          expect(validator.errors[:bill_address]).to_not be_empty
          expect(validator.errors[:ship_address]).to_not be_empty
        end
      end

      context "when bill_address and ship_address are present" do
        let(:bill_address) { instance_double(Spree::Address) }
        let(:ship_address) { instance_double(Spree::Address) }

        it "returns true" do
          expect(validator.valid?).to be true
          expect(validator.errors[:bill_address]).to be_empty
          expect(validator.errors[:ship_address]).to be_empty
        end
      end
    end

    describe "customer" do
      let(:standing_order) { instance_double(StandingOrder, standing_order_stubs.except(:customer)) }
      before { stub_validations(validator, validation_stubs.except(:customer_allowed?)) }
      before { expect(standing_order).to receive(:customer).at_least(:once) { customer } }

      context "when no customer is present" do
        let(:customer) { nil }

        it "adds an error and returns false" do
          expect(validator.valid?).to be false
          expect(validator.errors[:customer]).to_not be_empty
        end
      end

      context "when a customer is present" do
        let(:customer) { instance_double(Customer) }

        context "and the customer is not associated with the shop" do
          before { allow(customer).to receive(:enterprise) { double(:enterprise) } }

          it "adds an error and returns false" do
            expect(validator.valid?).to be false
            expect(validator.errors[:customer]).to_not be_empty
          end
        end

        context "and the customer is associated with the shop" do
          before { allow(customer).to receive(:enterprise) { shop } }

          it "returns true" do
            expect(validator.valid?).to be true
            expect(validator.errors[:customer]).to be_empty
          end
        end
      end
    end

    describe "schedule" do
      let(:standing_order) { instance_double(StandingOrder, standing_order_stubs.except(:schedule)) }
      before { stub_validations(validator, validation_stubs.except(:schedule_allowed?)) }
      before { expect(standing_order).to receive(:schedule).at_least(:once) { schedule } }

      context "when no schedule is present" do
        let(:schedule) { nil }

        it "adds an error and returns false" do
          expect(validator.valid?).to be false
          expect(validator.errors[:schedule]).to_not be_empty
        end
      end

      context "when a schedule is present" do
        let(:schedule) { instance_double(Schedule) }

        context "and the schedule is not associated with the shop" do
          before { allow(schedule).to receive(:coordinators) { [double(:enterprise)] } }

          it "adds an error and returns false" do
            expect(validator.valid?).to be false
            expect(validator.errors[:schedule]).to_not be_empty
          end
        end

        context "and the schedule is associated with the shop" do
          before { allow(schedule).to receive(:coordinators) { [shop] } }

          it "returns true" do
            expect(validator.valid?).to be true
            expect(validator.errors[:schedule]).to be_empty
          end
        end
      end
    end

    describe "credit card" do
      let(:standing_order) { instance_double(StandingOrder, standing_order_stubs.except(:payment_method)) }
      before { stub_validations(validator, validation_stubs.except(:credit_card_ok?)) }
      before { expect(standing_order).to receive(:payment_method).at_least(:once) { payment_method } }

      context "when using a Check payment method" do
        let(:payment_method) { instance_double(Spree::PaymentMethod, type: "Spree::PaymentMethod::Check") }

        it "returns true" do
          expect(validator.valid?).to be true
          expect(validator.errors[:standing_line_items]).to be_empty
        end
      end

      context "when using the StripeConnect payment gateway" do
        let(:payment_method) { instance_double(Spree::PaymentMethod, type: "Spree::Gateway::StripeConnect") }
        before { expect(standing_order).to receive(:credit_card_id).at_least(:once) { credit_card_id } }

        context "when a credit card is not present" do
          let(:credit_card_id) { nil }

          it "adds an error and returns false" do
            expect(validator.valid?).to be false
            expect(validator.errors[:credit_card]).to_not be_empty
          end
        end

        context "when a credit card is present" do
          let(:credit_card_id) { 12 }
          before { expect(standing_order).to receive(:customer).at_least(:once) { customer } }

          context "and the customer is not associated with a user" do
            let(:customer) { instance_double(Customer, user: nil) }

            it "adds an error and returns false" do
              expect(validator.valid?).to be false
              expect(validator.errors[:credit_card]).to_not be_empty
            end
          end

          context "and the customer is associated with a user" do
            let(:customer) { instance_double(Customer, user: user) }

            context "and the user has no credit cards which match that specified" do
              let(:user) { instance_double(Spree::User, credit_card_ids: [1, 2, 3, 4]) }

              it "adds an error and returns false" do
                expect(validator.valid?).to be false
                expect(validator.errors[:credit_card]).to_not be_empty
              end
            end

            context "and the user has a credit card which matches that specified" do
              let(:user) { instance_double(Spree::User, credit_card_ids: [1, 2, 3, 12]) }

              it "returns true" do
                expect(validator.valid?).to be true
                expect(validator.errors[:credit_card]).to be_empty
              end
            end
          end
        end
      end
    end

    describe "standing line items" do
      let(:standing_order) { instance_double(StandingOrder, standing_order_stubs) }
      before { stub_validations(validator, validation_stubs.except(:standing_line_items_present?)) }
      before { expect(standing_order).to receive(:standing_line_items).at_least(:once) { standing_line_items } }

      context "when no standing line items are present" do
        let(:standing_line_items) { [] }

        it "adds an error and returns false" do
          expect(validator.valid?).to be false
          expect(validator.errors[:standing_line_items]).to_not be_empty
        end
      end

      context "when standing line items are present but they are all marked for destruction" do
        let(:standing_line_item1) { instance_double(StandingLineItem, marked_for_destruction?: true) }
        let(:standing_line_items) { [standing_line_item1] }

        it "adds an error and returns false" do
          expect(validator.valid?).to be false
          expect(validator.errors[:standing_line_items]).to_not be_empty
        end
      end

      context "when standing line items are present and some and not marked for destruction" do
        let(:standing_line_item1) { instance_double(StandingLineItem, marked_for_destruction?: true) }
        let(:standing_line_item2) { instance_double(StandingLineItem, marked_for_destruction?: false) }
        let(:standing_line_items) { [standing_line_item1, standing_line_item2] }

        it "returns true" do
          expect(validator.valid?).to be true
          expect(validator.errors[:standing_line_items]).to be_empty
        end
      end
    end

    describe "variant availability" do
      let(:standing_order) { instance_double(StandingOrder, standing_order_stubs) }
      before { stub_validations(validator, validation_stubs.except(:requested_variants_available?)) }
      before { expect(standing_order).to receive(:standing_line_items).at_least(:once) { standing_line_items } }

      context "when no standing line items are present" do
        let(:standing_line_items) { [] }

        it "returns true" do
          expect(validator.valid?).to be true
          expect(validator.errors[:standing_line_items]).to be_empty
        end
      end

      context "when standing line items are present" do
        let(:variant1) { instance_double(Spree::Variant, id: 1) }
        let(:variant2) { instance_double(Spree::Variant, id: 2) }
        let(:standing_line_item1) { instance_double(StandingLineItem, variant: variant1) }
        let(:standing_line_item2) { instance_double(StandingLineItem, variant: variant2) }
        let(:standing_line_items) { [standing_line_item1] }

        context "but some variants are unavailable" do
          let(:product) { instance_double(Spree::Product, name: "some_name") }
          before do
            allow(validator).to receive(:available_variant_ids) { [variant2.id] }
            allow(variant1).to receive(:product) { product }
            allow(variant1).to receive(:full_name) { "some name" }
          end

          it "adds an error and returns false" do
            expect(validator.valid?).to be false
            expect(validator.errors[:standing_line_items]).to_not be_empty
          end
        end

        context "and all requested variants are available" do
          before { allow(validator).to receive(:available_variant_ids) { [variant1.id, variant2.id] } }

          it "returns true" do
            expect(validator.valid?).to be true
            expect(validator.errors[:standing_line_items]).to be_empty
          end
        end
      end
    end
  end
end
