require "spec_helper"

require "date_time_string_validator"
require "order_management/reports/enterprise_fee_summary/parameters"

describe OrderManagement::Reports::EnterpriseFeeSummary::Parameters do
  describe "validation" do
    let(:parameters) { described_class.new }

    it "allows all parameters to be blank" do
      expect(parameters).to be_valid
    end

    context "for type of parameters" do
      it { expect(subject).to validate_date_time_format_of(:start_at) }
      it { expect(subject).to validate_date_time_format_of(:end_at) }
      it { expect(subject).to validate_integer_array(:distributor_ids) }
      it { expect(subject).to validate_integer_array(:producer_ids) }
      it { expect(subject).to validate_integer_array(:order_cycle_ids) }
      it { expect(subject).to validate_integer_array(:enterprise_fee_ids) }
      it { expect(subject).to validate_integer_array(:shipping_method_ids) }
      it { expect(subject).to validate_integer_array(:payment_method_ids) }

      describe "requiring start_at to be before end_at" do
        let(:now) { Time.zone.now }

        it "adds error when start_at is after end_at" do
          allow(subject).to receive(:start_at) { now.to_s }
          allow(subject).to receive(:end_at) { (now - 1.hour).to_s }

          expect(subject).not_to be_valid
          expect(subject.errors[:end_at]).to eq([described_class::DATE_END_BEFORE_START_ERROR])
        end

        it "does not add error when start_at is before end_at" do
          allow(subject).to receive(:start_at) { now.to_s }
          allow(subject).to receive(:end_at) { (now + 1.hour).to_s }

          expect(subject).to be_valid
        end
      end
    end
  end
end
