require 'spec_helper'
require 'open_food_network/permissions'

describe ProductImporter do
  include AuthenticationWorkflow

  let!(:admin) { create(:admin_user) }
  let!(:user) { create_enterprise_user }
  let!(:enterprise) { create(:enterprise, owner: user, name: "Test Enterprise") }
  let!(:category) { create(:taxon, name: 'Vegetables') }
  let(:permissions) { OpenFoodNetwork::Permissions.new(user) }

  describe "importing products from a spreadsheet" do
    after { File.delete('/tmp/test-m.csv') }

    it "validates the entries" do
      csv_data = CSV.generate do |csv|
        csv << ["name", "supplier", "category", "on_hand", "price", "unit_value", "variant_unit", "variant_unit_scale"]
        csv << ["Carrots", "Test Enterprise", "Vegetables", "5", "3.20", "500", "weight", "1"]
        csv << ["Potatoes", "Test Enterprise", "Vegetables", "6", "6.50", "1000", "weight", "1000"]
      end
      File.write('/tmp/test-m.csv', csv_data)
      file = File.new('/tmp/test-m.csv')

      importer = ProductImporter.new(file, permissions.editable_enterprises)

      expect(importer.valid_count).to eq(2)
      expect(importer.invalid_count).to eq(0)
    end
  end

  # Test handling of filetypes
end
