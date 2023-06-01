# frozen_string_literal: true

require 'spec_helper'
require 'tasks/data/remove_transient_data'

describe RemoveTransientData do
  describe '#call' do
    let(:retention_period) { RemoveTransientData::RETENTION_PERIOD }

    before do
      allow(Spree::StateChange).to receive(:delete_all)
      allow(Spree::LogEntry).to receive(:delete_all)
      allow(RemoveTransientData::Session).to receive(:delete_all)
      allow(Rails.logger).to receive(:info)
    end

    it 'deletes state changes older than rentention_period' do
      Spree::StateChange.create(created_at: retention_period - 1.day)

      RemoveTransientData.new.call
      expect(Spree::StateChange.all).to be_empty
    end

    it 'deletes log entries older than retention_period' do
      Spree::LogEntry.create(created_at: retention_period - 1.day)

      expect { RemoveTransientData.new.call }
        .to change(Spree::LogEntry, :count).by(-1)
    end

    it 'deletes sessions older than retention_period' do
      RemoveTransientData::Session.create(session_id: 1, updated_at: retention_period - 1.day)

      RemoveTransientData.new.call

      expect(RemoveTransientData::Session.all).to be_empty
    end

    describe "deleting old carts" do
      let(:product) { create(:product) }
      let(:variant) { product.variants.first }

      let!(:cart) { create(:order, state: 'cart') }
      let!(:line_item) { create(:line_item, order: cart, variant: variant) }
      let!(:adjustment) { create(:adjustment, order: cart) }

      let!(:old_cart) { create(:order, state: 'cart', updated_at: retention_period - 1.day) }
      let!(:old_line_item) { create(:line_item, order: old_cart, variant: variant) }
      let!(:old_adjustment) { create(:adjustment, order: old_cart) }

      before do
        old_cart.update_columns(updated_at: retention_period - 1.day)
      end

      it 'deletes cart orders and related objects older than retention_period' do
        RemoveTransientData.new.call

        expect{ cart.reload }.to_not raise_error
        expect{ line_item.reload }.to_not raise_error
        expect{ adjustment.reload }.to_not raise_error

        expect{ old_cart.reload }.to raise_error ActiveRecord::RecordNotFound
        expect{ old_line_item.reload }.to raise_error ActiveRecord::RecordNotFound
        expect{ old_adjustment.reload }.to raise_error ActiveRecord::RecordNotFound
      end
    end
  end
end
