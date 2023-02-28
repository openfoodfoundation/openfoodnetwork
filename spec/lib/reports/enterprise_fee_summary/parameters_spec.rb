# frozen_string_literal: true

require "spec_helper"

require "date_time_string_validator"

module Reporting
  module Reports
    module EnterpriseFeeSummary
      describe Parameters do
        describe "validation" do
          let(:parameters) { described_class.new }

          it "allows all parameters to be blank" do
            expect(parameters).to be_valid
          end

          context "for type of parameters" do
            it { is_expected.to validate_date_time_format_of(:completed_at_gt) }
            it { is_expected.to validate_date_time_format_of(:completed_at_lt) }
            it { is_expected.to validate_integer_array(:distributor_ids) }
            it { is_expected.to validate_integer_array(:producer_ids) }
            it { is_expected.to validate_integer_array(:order_cycle_ids) }
            it { is_expected.to validate_integer_array(:enterprise_fee_ids) }
            it { is_expected.to validate_integer_array(:shipping_method_ids) }
            it { is_expected.to validate_integer_array(:payment_method_ids) }

            it "allows integer arrays to include blank string and cleans it up" do
              subject.distributor_ids = ["", "1"]
              subject.producer_ids = ["", "1"]
              subject.order_cycle_ids = ["", "1"]
              subject.enterprise_fee_ids = ["", "1"]
              subject.shipping_method_ids = ["", "1"]
              subject.payment_method_ids = ["", "1"]

              expect(subject).to be_valid

              expect(subject.distributor_ids).to eq(["1"])
              expect(subject.producer_ids).to eq(["1"])
              expect(subject.order_cycle_ids).to eq(["1"])
              expect(subject.enterprise_fee_ids).to eq(["1"])
              expect(subject.shipping_method_ids).to eq(["1"])
              expect(subject.payment_method_ids).to eq(["1"])
            end

            describe "requiring completed_at_gt to be before completed_at_lt" do
              let(:now) { Time.zone.now.utc }

              it "adds error when completed_at_gt is after completed_at_lt" do
                allow(subject).to receive(:completed_at_gt) { now.to_s }
                allow(subject).to receive(:completed_at_lt) { (now - 1.hour).to_s }

                expect(subject).not_to be_valid
                error_message = described_class.date_end_before_start_error_message
                expect(subject.errors[:completed_at_lt]).to eq([error_message])
              end

              it "does not add error when completed_at_gt is before completed_at_lt" do
                allow(subject).to receive(:completed_at_gt) { now.to_s }
                allow(subject).to receive(:completed_at_lt) { (now + 1.hour).to_s }

                expect(subject).to be_valid
              end
            end
          end
        end

        describe "smoke authorization" do
          let!(:order_cycle) { create(:order_cycle) }
          let!(:user) { create(:user) }

          let(:permissions) do
            Permissions.new(nil).tap do |instance|
              allow(instance).to receive(:allowed_order_cycles) { [order_cycle] }
            end
          end

          it "does not raise error when the parameters are allowed" do
            parameters = described_class.new(order_cycle_ids: [order_cycle.id.to_s])
            expect { parameters.authorize!(permissions) }.not_to raise_error
          end

          it "raises error when the parameters are not allowed" do
            parameters = described_class.new(order_cycle_ids: [(order_cycle.id + 1).to_s])
            expect { parameters.authorize!(permissions) }
              .to raise_error(ParameterNotAllowedError)
          end
        end
      end
    end
  end
end
