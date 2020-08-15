# frozen_string_literal: true

require 'spec_helper'
require 'tasks/data/remove_transient_data'

describe RemoveTransientData do
  describe '#call' do
    let(:retention_period) { RemoveTransientData.new.__send__(:retention_period) }

    before do
      allow(Spree::StateChange).to receive(:delete_all)
      allow(Spree::LogEntry).to receive(:delete_all)
      allow(RemoveTransientData::Session).to receive(:delete_all)
      allow(Rails.logger).to receive(:info)
    end

    it 'deletes state changes older than a month' do
      RemoveTransientData.new.call

      expect(Spree::StateChange)
        .to have_received(:delete_all)
        .with("created_at < '#{retention_period}'")
    end

    it 'deletes log entries older than a month' do
      RemoveTransientData.new.call

      expect(Spree::LogEntry)
        .to have_received(:delete_all)
        .with("created_at < '#{retention_period}'")
    end

    it 'deletes sessions older than two weeks' do
      RemoveTransientData.new.call

      expect(RemoveTransientData::Session)
        .to have_received(:delete_all)
        .with("updated_at < '#{retention_period}'")
    end
  end
end
