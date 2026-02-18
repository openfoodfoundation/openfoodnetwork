# frozen_string_literal: true

RSpec.describe Vouchers::Vine do
  describe 'validations' do
    subject { build(:vine_voucher) }

    it { is_expected.to validate_presence_of(:amount) }
    it { is_expected.to validate_numericality_of(:amount).is_greater_than(0) }

    describe "#code" do
      subject { build(:vine_voucher, code: 'vine_code', enterprise:, external_voucher_id: ) }

      let(:external_voucher_id) { SecureRandom.uuid }
      let(:enterprise) { create(:enterprise) }

      it {
        is_expected.to validate_uniqueness_of(:code).scoped_to(
          [:enterprise_id, :external_voucher_id]
        )
      }

      it "can be reused within the same enterprise" do
        subject.save!
        # Voucher with the same code but different external_voucher_id, it is mapped to a
        # different voucher in VINE
        voucher = build(:vine_voucher, code: 'vine_code', enterprise: )
        expect(voucher.valid?).to be(true)
      end

      it "can be used by mutiple enterprises" do
        subject.save!
        # Voucher with the same code and external_voucher_id, ie exiting VINE voucher used by
        # another enterprise
        voucher = build(:vine_voucher, code: 'vine_code', enterprise: build(:enterprise),
                                       external_voucher_id: )
        expect(voucher.valid?).to be(true)
      end
    end
  end

  describe '#compute_amount' do
    let(:order) { create(:order_with_totals) }

    before do
      order.update_columns(item_total: 15)
    end

    context 'when order total is more than the voucher' do
      subject { create(:vine_voucher, amount: 5) }

      it 'uses the voucher total' do
        expect(subject.compute_amount(order).to_f).to eq(-5)
      end
    end

    context 'when order total is less than the voucher' do
      subject { create(:vine_voucher, amount: 20) }

      it 'matches the order total' do
        expect(subject.compute_amount(order).to_f).to eq(-15)
      end
    end
  end

  describe "#rate" do
    subject do
      create(:vine_voucher, code: 'new_code', amount: 5)
    end
    let(:order) { create(:order_with_totals) }

    before do
      order.update_columns(item_total: 10)
    end

    it "returns the voucher rate" do
      # rate = -voucher_amount / order.pre_discount_total
      # -5 / 10 = -0.5
      expect(subject.rate(order).to_f).to eq(-0.5)
    end
  end
end
