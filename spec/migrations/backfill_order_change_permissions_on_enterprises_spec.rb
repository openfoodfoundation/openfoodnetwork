# frozen_string_literal: true

require 'spec_helper'
require_relative '../../db/migrate/20261123000001_backfill_order_change_permissions_on_enterprises'

RSpec.describe BackfillOrderChangePermissionsOnEnterprises do
  subject { described_class.new }

  let(:permissions) {
    [:allow_order_additions, :allow_order_removals, :allow_order_cancellation]
  }

  describe '#up' do
    it "grants all three permissions to shops that allowed order changes" do
      shop = create(:distributor_enterprise)
      shop.update_columns(allow_order_changes: true, allow_order_additions: false,
                          allow_order_removals: false, allow_order_cancellation: false)

      subject.up

      expect(shop.reload.slice(*permissions).values).to all be true
    end

    it "grants none to shops that didn't allow order changes" do
      shop = create(:distributor_enterprise)
      shop.update_columns(allow_order_changes: false, allow_order_additions: false,
                          allow_order_removals: false, allow_order_cancellation: false)

      subject.up

      expect(shop.reload.slice(*permissions).values).to all be false
    end
  end
end
