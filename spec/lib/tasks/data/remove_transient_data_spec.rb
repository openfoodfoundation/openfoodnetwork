# frozen_string_literal: true

require 'tasks/data/remove_transient_data'

RSpec.describe RemoveTransientData do
  describe '#call' do
    before do
      allow(Spree::StateChange).to receive(:delete_all)
      allow(Spree::LogEntry).to receive(:delete_all)
      allow(RemoveTransientData::Session).to receive(:delete_all)
      allow(Rails.logger).to receive(:info)
    end

    it 'deletes state changes older than retention period' do
      remover = RemoveTransientData.new
      Spree::StateChange.create(created_at: remover.expiration_date - 1.day)
      remover.call

      expect(Spree::StateChange.all).to be_empty
    end

    it 'deletes log entries older than retention period' do
      remover = RemoveTransientData.new
      Spree::LogEntry.create(created_at: remover.expiration_date - 1.day)

      expect { remover.call }
        .to change { Spree::LogEntry.count }.by(-1)
    end

    it 'deletes sessions older than retention period' do
      remover = RemoveTransientData.new
      RemoveTransientData::Session.create(session_id: 1,
                                          updated_at: remover.expiration_date - 1.day)

      remover.call

      expect(RemoveTransientData::Session.all).to be_empty
    end

    describe "deleting old carts" do
      let(:product) { create(:product) }
      let(:variant) { product.variants.first }

      let!(:cart) { create(:order, state: 'cart') }
      let!(:line_item) { create(:line_item, order: cart, variant:) }
      let!(:adjustment) { create(:adjustment, order: cart) }

      let!(:remover) { RemoveTransientData.new }
      let!(:old_cart) { create(:order, state: 'cart', updated_at: remover.expiration_date - 1.day) }
      let!(:old_line_item) { create(:line_item, order: old_cart, variant:) }
      let!(:old_adjustment) { create(:adjustment, order: old_cart) }

      it 'deletes cart orders and related objects older than retention period' do
        remover.call

        expect{ cart.reload }.not_to raise_error
        expect{ line_item.reload }.not_to raise_error
        expect{ adjustment.reload }.not_to raise_error

        expect{ old_cart.reload }.to raise_error ActiveRecord::RecordNotFound
        expect{ old_line_item.reload }.to raise_error ActiveRecord::RecordNotFound
        expect{ old_adjustment.reload }.to raise_error ActiveRecord::RecordNotFound
      end
    end
  end
end
