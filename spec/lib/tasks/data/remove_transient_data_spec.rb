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

    it 'deletes state changes older than rentention_period' do
      Spree::StateChange.create(created_at: retention_period - 1.day)

      RemoveTransientData.new.call
      expect(Spree::StateChange.all).to be_empty
    end

    it 'deletes log entries older than a month' do
      Spree::LogEntry.create(created_at: retention_period - 1.day)

      RemoveTransientData.new.call

      expect(Spree::LogEntry.all).to be_empty
    end

    it 'deletes sessions older than retention_period' do
      RemoveTransientData::Session.create(session_id: 1, updated_at: retention_period - 1.day)

      RemoveTransientData.new.call

      expect(RemoveTransientData::Session.all).to be_empty
    end
  end
end
