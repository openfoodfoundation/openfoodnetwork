# frozen_string_literal: true

RSpec.describe Orders::GenerateInvoiceService do
  let!(:order) { create(:completed_order_with_fees) }
  let!(:invoice_data_generator){ InvoiceDataGenerator.new(order) }
  let!(:latest_invoice){
    create(:invoice,
           order:,
           date: Time.zone.today - 2.days,
           data: invoice_data_generator.serialize_for_invoice)
  }

  let(:instance) { described_class.new(order) }
  let(:comparator){ double("Orders::CompareInvoiceService") }

  before do
    allow(instance).to receive(:comparator).and_return(comparator)
  end

  describe "#generate_or_update_latest_invoice" do
    let(:subject) { instance.generate_or_update_latest_invoice }
    context "when can generate new invoice" do
      before do
        expect(comparator).to receive(:can_generate_new_invoice?).and_return(true)
      end

      it "should create a new invoice" do
        expect(instance).to receive(:invoice_data)
        expect{ subject }.to change{ order.invoices.count }.by(1)
        expect(order.invoices.order('created_at desc').first.number).to eq(2)
      end
    end

    context "can update latest invoice" do
      before do
        allow(comparator).to receive(:can_generate_new_invoice?).and_return(false)
        allow(comparator).to receive(:can_update_latest_invoice?).and_return(true)
        order.update!(note: "This is an updated note")
      end

      it "should update the latest invoice" do
        expect{ subject }.to change{ latest_invoice.reload.data }
          .and change{ order.invoices.count }.by(0)
      end

      context "when there are more than one invoice" do
        before do
          latest_invoice.update!(number: 2, created_at: 1.day.ago)
          create(:invoice, order:, number: 1, created_at: 2.days.ago)
        end
        it "should update the most recent invoice" do
          expect{ subject }.to change{ latest_invoice.reload.data }
            .and change{ latest_invoice.date }.to(Time.zone.today)
            .and change{ latest_invoice.number }.by(0)
            .and change{ order.invoices.count }.by(0)
        end
      end
    end

    context "when can't generate new invoice or update latest invoice" do
      before do
        allow(comparator).to receive(:can_generate_new_invoice?).and_return(false)
        allow(comparator).to receive(:can_update_latest_invoice?).and_return(false)
      end

      it "should not create or update invoices" do
        expect(instance).not_to receive(:invoice_data)
        expect{ subject }.to change{ order.invoices.count }.by(0)
      end
    end
  end
end
