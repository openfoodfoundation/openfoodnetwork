# frozen_string_literal: true

require "spec_helper"

module Reporting
  module Reports
    module EnterpriseFeeSummary
      describe Authorizer do
        let(:user) { create(:user) }

        let(:parameters) { Parameters.new(params) }
        let(:permissions) { Permissions.new(user) }
        let(:authorizer) { Authorizer.new(parameters, permissions) }

        context "for distributors" do
          before do
            allow(permissions).to receive(:allowed_distributors) do
              stub_model_collection(Enterprise, :id, ["1", "2", "3"])
            end
          end

          context "when distributors are allowed" do
            let(:params) { { distributor_ids: ["1", "3"] } }

            it "does not raise error" do
              expect { authorizer.authorize! }.not_to raise_error
            end
          end

          context "when a distributor is not allowed" do
            let(:params) { { distributor_ids: ["1", "4"] } }

            it "raises ParameterNotAllowedError" do
              expect { authorizer.authorize! }
                .to raise_error(ParameterNotAllowedError)
            end
          end
        end

        context "for producers" do
          before do
            allow(permissions).to receive(:allowed_producers) do
              stub_model_collection(Enterprise, :id, ["1", "2", "3"])
            end
          end

          context "when producers are allowed" do
            let(:params) { { producer_ids: ["1", "3"] } }

            it "does not raise error" do
              expect { authorizer.authorize! }.not_to raise_error
            end
          end

          context "when a producer is not allowed" do
            let(:params) { { producer_ids: ["1", "4"] } }

            it "raises ParameterNotAllowedError" do
              expect { authorizer.authorize! }
                .to raise_error(ParameterNotAllowedError)
            end
          end
        end

        context "for order cycles" do
          before do
            allow(permissions).to receive(:allowed_order_cycles) do
              stub_model_collection(OrderCycle, :id, ["1", "2", "3"])
            end
          end

          context "when order cycles are allowed" do
            let(:params) { { order_cycle_ids: ["1", "3"] } }

            it "does not raise error" do
              expect { authorizer.authorize! }.not_to raise_error
            end
          end

          context "when an order cycle is not allowed" do
            let(:params) { { order_cycle_ids: ["1", "4"] } }

            it "raises ParameterNotAllowedError" do
              expect { authorizer.authorize! }
                .to raise_error(ParameterNotAllowedError)
            end
          end
        end

        context "for enterprise fees" do
          before do
            allow(permissions).to receive(:allowed_enterprise_fees) do
              stub_model_collection(EnterpriseFee, :id, ["1", "2", "3"])
            end
          end

          context "when enterprise fees are allowed" do
            let(:params) { { enterprise_fee_ids: ["1", "3"] } }

            it "does not raise error" do
              expect { authorizer.authorize! }.not_to raise_error
            end
          end

          context "when an enterprise fee is not allowed" do
            let(:params) { { enterprise_fee_ids: ["1", "4"] } }

            it "raises ParameterNotAllowedError" do
              expect { authorizer.authorize! }
                .to raise_error(ParameterNotAllowedError)
            end
          end
        end

        context "for shipping methods" do
          before do
            allow(permissions).to receive(:allowed_shipping_methods) do
              stub_model_collection(Spree::ShippingMethod, :id, ["1", "2", "3"])
            end
          end

          context "when shipping methods are allowed" do
            let(:params) { { shipping_method_ids: ["1", "3"] } }

            it "does not raise error" do
              expect { authorizer.authorize! }.not_to raise_error
            end
          end

          context "when a shipping method is not allowed" do
            let(:params) { { shipping_method_ids: ["1", "4"] } }

            it "raises ParameterNotAllowedError" do
              expect { authorizer.authorize! }
                .to raise_error(ParameterNotAllowedError)
            end
          end
        end

        context "for payment methods" do
          before do
            allow(permissions).to receive(:allowed_payment_methods) do
              stub_model_collection(Spree::PaymentMethod, :id, ["1", "2", "3"])
            end
          end

          context "when payment methods are allowed" do
            let(:params) { { payment_method_ids: ["1", "3"] } }

            it "does not raise error" do
              expect { authorizer.authorize! }.not_to raise_error
            end
          end

          context "when a payment method is not allowed" do
            let(:params) { { payment_method_ids: ["1", "4"] } }

            it "raises ParameterNotAllowedError" do
              expect { authorizer.authorize! }
                .to raise_error(ParameterNotAllowedError)
            end
          end
        end

        def stub_model_collection(model, attribute_name, attribute_list)
          attribute_list.map do |attribute_value|
            stub_model(model, attribute_name => attribute_value)
          end
        end

        def stub_model(model, params)
          model.new.tap do |instance|
            allow(instance).to receive_messages(params)
          end
        end
      end
    end
  end
end
