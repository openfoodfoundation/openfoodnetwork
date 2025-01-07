# frozen_string_literal: true

require 'spec_helper'
require_relative "../../db/migrate/#{File.basename(__FILE__, '_spec.rb')}"

RSpec.describe CopyAdminAttributeToUsers do
  describe "#up" do
    it "marks current admins as admin" do
      admin = create(:admin_user)
      enterprise_user = create(:enterprise_user)
      customer = create(:user)

      expect { subject.up }.to change {
        admin.reload.admin
      }.from(false).to(true)

      expect(enterprise_user.reload.admin).to eq false
      expect(customer.reload.admin).to eq false
    end
  end
end
