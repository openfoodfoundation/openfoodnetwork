# frozen_string_literal: true

require 'spec_helper'
require_relative '../../db/migrate/20211027140313_migrate_customer_names'

describe MigrateCustomerNames do
  subject { MigrateCustomerNames.new }

  let!(:enterprise1) { create(:enterprise) }
  let!(:enterprise2) { create(:enterprise) }
  let!(:enterprise3) { create(:enterprise) }
  let!(:enterprise4) { create(:enterprise) }

  before do
    Spree::Preference.create(value: true,
                             value_type: "boolean",
                             key: "/enterprise/show_customer_names_to_suppliers/#{enterprise1.id}")
    Spree::Preference.create(value: false,
                             value_type: "boolean",
                             key: "/enterprise/show_customer_names_to_suppliers/#{enterprise2.id}")
    Spree::Preference.create(value: true,
                             value_type: "boolean",
                             key: "/enterprise/show_customer_names_to_suppliers/#{enterprise4.id}")
  end

  describe '#migrate_customer_names_preferences!' do
    it "migrates the preference to the enterprise" do
      subject.migrate_customer_names_preferences!

      expect(enterprise1.reload.show_customer_names_to_suppliers?).to be true
      expect(enterprise2.reload.show_customer_names_to_suppliers?).to be false
      expect(enterprise3.reload.show_customer_names_to_suppliers?).to be false # was nil
      expect(enterprise4.reload.show_customer_names_to_suppliers?).to be true
    end
  end
end
