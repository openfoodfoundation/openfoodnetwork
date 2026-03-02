# frozen_string_literal: true

RSpec.describe VoucherAdjustmentsController do
  let(:user) { order.user }
  let(:address) { create(:address) }
  let(:distributor) { create(:distributor_enterprise, with_payment_and_shipping: true) }
  let(:order_cycle) { create(:order_cycle, distributors: [distributor]) }
  let(:exchange) { order_cycle.exchanges.outgoing.first }
  let!(:order) do
    create(
      :order_with_line_items,
      line_items_count: 1,
      distributor:,
      order_cycle:,
      bill_address: address,
      ship_address: address
    )
  end
  let(:shipping_method) { distributor.shipping_methods.first }
  let(:voucher) { create(:voucher_flat_rate, code: 'some_code', enterprise: distributor) }

  before do
    order.update!(created_by: user)

    order.select_shipping_method shipping_method.id
    Orders::WorkflowService.new(order).advance_to_payment

    sign_in user
  end

  describe "POST voucher_adjustments" do
    let(:params) { { order: { voucher_code: voucher.code } } }

    it "adds a voucher to the user's current order" do
      expect {
        post("/voucher_adjustments", params:)
      }.to change { order.reload.voucher_adjustments.count }.by(1)
      expect(response).to be_successful
    end

    context "when voucher doesn't exist" do
      let(:params) { { order: { voucher_code: "non_voucher" } } }

      it "returns 422 and an error message" do
        post("/voucher_adjustments", params:)

        expect(response).to be_unprocessable
        expect(flash[:error]).to match "Voucher code invalid."
      end
    end

    context "when adding fails" do
      it "returns 422 and an error message" do
        # Create a non valid adjustment
        bad_adjustment = build(:adjustment, label: nil)
        allow(voucher).to receive(:create_adjustment).and_return(bad_adjustment)
        allow(Voucher).to receive(:find_by).and_return(voucher)

        post("/voucher_adjustments", params:)

        expect(response).to be_unprocessable
        expect(flash[:error]).to match("Voucher code There was an error while adding the voucher")
      end
    end

    context "when the order has a payment and payment feed" do
      let(:payment_method) { create(:payment_method, calculator:) }
      let(:calculator) { Calculator::FlatPercentItemTotal.new(preferred_flat_percent: 10) }

      before do
        create(:payment, order:, payment_method:, amount: order.total)
      end

      it "removes existing payments" do
        expect do
          post "/voucher_adjustments", params:
        end.to change { order.reload.payments.count }.from(1).to(0)
      end

      it "removes existing payment fees" do
        expect do
          post "/voucher_adjustments", params:
        end.to change { order.reload.all_adjustments.payment_fee.count }.from(1).to(0)
      end
    end

    context "with a VINE voucher", feature: :connected_apps do
      let(:vine_voucher_validator) { instance_double(Vine::VoucherValidatorService) }

      before do
        allow(Vine::VoucherValidatorService).to receive(:new).and_return(vine_voucher_validator)
      end

      context "with a new voucher" do
        let(:params) { { order: { voucher_code: vine_voucher_code } } }
        let(:vine_voucher_code) { "PQ3187" }

        context "with a valid voucher" do
          it "verifies the voucher with VINE API" do
            expect(vine_voucher_validator).to receive(:validate)
            allow(vine_voucher_validator).to receive(:errors).and_return({})

            post "/voucher_adjustments", params:
          end

          it "adds a voucher to the user's current order" do
            vine_voucher = create(:vine_voucher, code: vine_voucher_code)
            mock_vine_voucher_validator(voucher: vine_voucher)

            post("/voucher_adjustments", params:)

            expect(response).to be_successful
            expect(order.reload.voucher_adjustments.length).to eq(1)
          end
        end

        context "when coordinator is not connected to VINE" do
          it "returns 422 and an error message" do
            mock_vine_voucher_validator(voucher: nil)

            post("/voucher_adjustments", params:)

            expect(response).to be_unprocessable
            expect(flash[:error]).to match "Voucher code invalid."
          end
        end

        context "when there is an API error" do
          it "returns 422 and an error message" do
            mock_vine_voucher_validator(
              voucher: nil,
              errors: { vine_api: "There was an error communicating with the API" }
            )

            post("/voucher_adjustments", params:)

            expect(response).to be_unprocessable
            expect(flash[:error]).to match "There was an error while adding the voucher"
          end
        end

        context "when the voucher doesn't exist" do
          it "returns 422 and an error message" do
            mock_vine_voucher_validator(voucher: nil,
                                        errors: { not_found_voucher: "The voucher doesn't exist" })

            post("/voucher_adjustments", params:)

            expect(response).to be_unprocessable
            expect(flash[:error]).to match "Voucher code invalid"
          end
        end

        context "when the voucher is invalid voucher" do
          it "returns 422 and an error message" do
            mock_vine_voucher_validator(voucher: nil,
                                        errors: { invalid_voucher: "The voucher is not valid" })

            post("/voucher_adjustments", params:)

            expect(response).to be_unprocessable
            expect(flash[:error]).to match "The voucher is not valid"
          end
        end

        context "when voucher has expired" do
          it "returns 422 and an error message" do
            mock_vine_voucher_validator(voucher: nil,
                                        errors: { invalid_voucher: "The voucher has expired" })

            post("/voucher_adjustments", params:)

            expect(response).to be_unprocessable
            expect(flash[:error]).to match "The voucher has expired"
          end
        end

        context "when creating a new voucher fails" do
          it "returns 422 and an error message" do
            vine_voucher = build(:vine_voucher, code: vine_voucher_code,
                                                enterprise: distributor, amount: "")
            mock_vine_voucher_validator(voucher: vine_voucher)

            post("/voucher_adjustments", params:)

            expect(response).to be_unprocessable
            expect(flash[:error]).to match(
              "There was an error while creating the voucher: Amount can't be blank and " \
              "Amount is not a number"
            )
          end
        end
      end

      context "with an existing voucher" do
        let(:params) { { order: { voucher_code: vine_voucher_code } } }
        let(:vine_voucher_code) { "PQ3187" }

        it "verify the voucher with VINE API" do
          expect(vine_voucher_validator).to receive(:validate)
          allow(vine_voucher_validator).to receive(:errors).and_return({})

          post "/voucher_adjustments", params:
        end

        it "adds a voucher to the user's current order" do
          vine_voucher = create(:vine_voucher, code: vine_voucher_code,
                                               enterprise: distributor)
          mock_vine_voucher_validator(voucher: vine_voucher)

          expect {
            post("/voucher_adjustments", params:)
          }.to change { order.reload.voucher_adjustments.count }.by(1)
          expect(response).to be_successful
        end

        context "when updating the voucher fails" do
          it "returns 422 and an error message" do
            vine_voucher = build(:vine_voucher, code: vine_voucher_code,
                                                enterprise: distributor, amount: "")
            mock_vine_voucher_validator(voucher: vine_voucher)

            post("/voucher_adjustments", params:)

            expect(response).to be_unprocessable
            expect(flash[:error]).to match(
              "There was an error while creating the voucher: Amount can't be blank and " \
              "Amount is not a number"
            )
          end
        end

        context "when voucher has expired" do
          it "returns 422 and an error message" do
            vine_voucher = build(:vine_voucher, code: vine_voucher_code,
                                                enterprise: distributor)
            mock_vine_voucher_validator(voucher: vine_voucher,
                                        errors: { invalid_voucher: "The voucher has expired" })

            post("/voucher_adjustments", params:)

            expect(response).to be_unprocessable
            expect(flash[:error]).to match "The voucher has expired"
          end
        end
      end
    end
  end

  describe "DELETE voucher_adjustments/:id" do
    let!(:adjustment) { voucher.create_adjustment(voucher.code, order) }

    it "deletes the voucher adjustment" do
      delete "/voucher_adjustments/#{adjustment.id}"

      expect(order.voucher_adjustments.reload.length).to eq(0)
    end

    it "render a success response" do
      delete "/voucher_adjustments/#{adjustment.id}"

      expect(response).to be_successful
    end

    context "when adjustment doesn't exist" do
      it "does nothing" do
        delete "/voucher_adjustments/-1"

        expect(order.voucher_adjustments.reload.length).to eq(1)
      end

      it "render a success response" do
        delete "/voucher_adjustments/-1"

        expect(response).to be_successful
      end
    end

    context "when tax excluded from price" do
      it "deletes all voucher adjustment" do
        # Add a tax adjustment
        adjustment_attributes = {
          amount: 2.00,
          originator: adjustment.originator,
          order:,
          label: "Tax #{adjustment.label}",
          mandatory: false,
          state: 'closed',
          tax_category: nil,
          included_tax: 0
        }
        order.adjustments.create(adjustment_attributes)

        delete "/voucher_adjustments/#{adjustment.id}"

        expect(order.voucher_adjustments.reload.length).to eq(0)
      end
    end
  end

  def mock_vine_voucher_validator(voucher:, errors: {})
    allow(vine_voucher_validator).to receive(:validate).and_return(voucher)
    allow(vine_voucher_validator).to receive(:errors).and_return(errors)
  end
end
