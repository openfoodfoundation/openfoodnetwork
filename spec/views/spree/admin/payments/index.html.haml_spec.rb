# frozen_string_literal: true

require "spec_helper"

describe "spree/admin/payments/index.html.haml" do
  let(:order) { build(:order) }
  let(:payment) { build(:payment, id: 1, created_at: Time.now) }

  before do
    assign(:order, order)
    assign(:payments, [payment])
  end

  context 'when the order has outstanding balance' do
    before do
      allow(order).to receive(:outstanding_balance) { 100.00 }
    end

    it 'renders the order balance' do
      render
      expect(rendered.tr("\n","")).to include(
        "<h5 class='outstanding-balance'>Balance due:<strong>$100.00</strong></h5>"
      )
    end
  end

  context 'when the order has no outstanding balance' do
    before do
      allow(order).to receive(:outstanding_balance) { 0 }
    end

    it 'does not render the order balance' do
      render
      expect(rendered).not_to include('<h5 class="outstanding-balance">')
    end
  end
end
