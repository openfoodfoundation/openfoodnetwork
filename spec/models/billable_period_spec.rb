require 'spec_helper'

describe Customer, type: :model do
  describe 'ensure_correct_adjustment' do
    let!(:start_of_july) { Time.now.beginning_of_year + 6.months }
    let!(:user) { create(:user) }
    let!(:invoice) { create(:order, user: user) }
    let!(:billable_period) { create(:billable_period, owner: user, begins_at: start_of_july, ends_at: start_of_july + 12.days) }

    before do
      allow(billable_period).to receive(:bill) { 99 }
      allow(billable_period).to receive(:adjustment_label) { "Label for adjustment" }
      Spree::Config.set({ account_bill_inc_tax: true })
      Spree::Config.set({ account_bill_tax_rate: 0.1 })
    end

    context "when no adjustment currently exists" do
      it "creates an adjustment on the given order" do
        expect(invoice.total_tax).to eq 0.0
        expect(billable_period.adjustment).to be nil
        billable_period.ensure_correct_adjustment_for(invoice)
        expect(billable_period.adjustment).to be_a Spree::Adjustment
        expect(invoice.total_tax).to eq 9.0
      end
    end
  end
end
