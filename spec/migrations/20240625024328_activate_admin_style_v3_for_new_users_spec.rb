# frozen_string_literal: true

require 'spec_helper'
require_relative '../../db/migrate/20240625024328_activate_admin_style_v3_for_new_users'

RSpec.describe ActivateAdminStyleV3ForNewUsers do
  it "activates new product screen for new users" do
    Timecop.freeze Time.zone.parse("2024-07-03") do
      user_new = create(:user)

      expect {
        subject.up
      }.to change {
        OpenFoodNetwork::FeatureToggle.enabled?(:admin_style_v3, user_new)
      }.to(true)
    end
  end

  it "doesn't activate new product screen for old users" do
    Timecop.freeze Time.zone.parse("2024-07-02") do
      user_old = create(:user)

      expect {
        subject.up
      }.not_to change {
        OpenFoodNetwork::FeatureToggle.enabled?(:admin_style_v3, user_old)
      }
    end
  end
end
