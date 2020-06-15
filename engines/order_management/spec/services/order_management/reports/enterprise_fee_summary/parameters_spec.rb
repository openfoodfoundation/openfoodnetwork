require "spec_helper"

require "date_time_string_validator"

describe OrderManagement::Reports::EnterpriseFeeSummary::Parameters do
  describe "validation" do
    let(:parameters) { described_class.new }

    it "allows all parameters to be blank" do
      expect(parameters).to be_valid
    end

    context "for type of parameters" do
      it { is_expected.to validate_date_time_format_of(:start_at) }
      it { is_expected.to validate_date_time_format_of(:end_at) }
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

      describe "requiring start_at to be before end_at" do
        let(:now) { Time.zone.now.utc }

        it "adds error when start_at is after end_at" do
          allow(subject).to receive(:start_at) { now.to_s }
          allow(subject).to receive(:end_at) { (now - 1.hour).to_s }

          expect(subject).not_to be_valid
          error_message = described_class.date_end_before_start_error_message
          expect(subject.errors[:end_at]).to eq([error_message])
        end

        it "does not add error when start_at is before end_at" do
          allow(subject).to receive(:start_at) { now.to_s }
          allow(subject).to receive(:end_at) { (now + 1.hour).to_s }

          expect(subject).to be_valid
        end
      end
    end
  end

  describe "smoke authorization" do
    let!(:order_cycle) { create(:order_cycle) }
    let!(:user) { create(:user) }

    let(:permissions) do
      report_klass::Permissions.new(nil).tap do |instance|
        instance.stub(allowed_order_cycles: [order_cycle])
      end
    end

    it "does not raise error when the parameters are allowed" do
      parameters = described_class.new(order_cycle_ids: [order_cycle.id.to_s])
      expect { parameters.authorize!(permissions) }.not_to raise_error
    end

    it "raises error when the parameters are not allowed" do
      parameters = described_class.new(order_cycle_ids: [(order_cycle.id + 1).to_s])
      expect { parameters.authorize!(permissions) }
        .to raise_error(Reports::Authorizer::ParameterNotAllowedError)
    end
  end

  def report_klass
    OrderManagement::Reports::EnterpriseFeeSummary
  end
end
