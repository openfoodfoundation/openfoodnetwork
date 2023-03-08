# frozen_string_literal: true

require 'spec_helper'

describe OrderInvoiceComparator do
  describe '#equal?' do
    let!(:order) { create(:completed_order_with_fees) }
    let(:current_state_invoice){ order.current_state_invoice }
    let!(:invoice){ create(:invoice, order: order) }

    context "changes on the order object" do
      it "returns true if the order didn't change" do
        expect(OrderInvoiceComparator.new.equal?(current_state_invoice, invoice)).to be true
      end
  
      it "returns true if a relevant attribute changes" do
        order.update!(note: 'THIS IS AN UPDATE')
  
        expect(OrderInvoiceComparator.new.equal?(current_state_invoice, invoice)).to be false
      end
  
      it "returns true if a non-relevant attribute changes" do
        order.update!(last_ip_address: "192.168.172.165")
  
        expect(OrderInvoiceComparator.new.equal?(current_state_invoice, invoice)).to be true
      end
    end

    context "change on associate objects (belong_to)" do
      let(:distributor){ order.distributor }

      it "returns false if the distributor change relavant attribute" do
        distributor.update!(name: 'THIS IS A NEW NAME')
  
        expect(OrderInvoiceComparator.new.equal?(current_state_invoice, invoice)).to be false
      end

      it "returns true if the distributor change non-relavant attribute" do
        distributor.update!(description: 'THIS IS A NEW DESCRIPTION')
  
        expect(OrderInvoiceComparator.new.equal?(current_state_invoice, invoice)).to be true
      end
    end

    context "changes on associate objects (has_many)" do
      let(:line_item){ order.line_items.first }
      it "return true if relavant attribute change" do
        line_item.update!(quantity: line_item.quantity + 1)
  
        expect(OrderInvoiceComparator.new.equal?(current_state_invoice, invoice)).to be false
      end
    end
  end
end