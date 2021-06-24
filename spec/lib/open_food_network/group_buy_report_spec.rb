# frozen_string_literal: true

require 'spec_helper'
require 'open_food_network/group_buy_report'

module OpenFoodNetwork
  describe GroupBuyReport do
    before(:each) do
      @orders = []
      bill_address = create(:address)
      distributor_address = create(:address, address1: "distributor address", city: 'The Shire',
                                             zipcode: "1234")
      distributor = create(:distributor_enterprise, address: distributor_address)

      @supplier1 = create(:supplier_enterprise)
      @variant1 = create(:variant)
      @variant1.product.supplier = @supplier1
      @variant1.product.save!
      @variant1.reload

      shipping_instructions = "pick up on thursday please!"

      order1 = create(:order, distributor: distributor, bill_address: bill_address,
                              special_instructions: shipping_instructions)
      line_item11 = create(:line_item, variant: @variant1, order: order1)
      @orders << order1.reload

      order2 = create(:order, distributor: distributor, bill_address: bill_address,
                              special_instructions: shipping_instructions)
      line_item21 = create(:line_item, variant: @variant1, order: order2)

      @variant2 = create(:variant)
      @variant2.product.supplier = @supplier1
      @variant2.product.save!

      line_item22 = create(:line_item, variant: @variant2, order: order2)
      @orders << order2.reload

      @supplier2 = create(:supplier_enterprise)
      @variant3 = create(:variant, weight: nil)
      @variant3.product.supplier = @supplier2
      @variant3.product.save!

      order3 = create(:order, distributor: distributor, bill_address: bill_address,
                              special_instructions: shipping_instructions)
      line_item31 = create(:line_item, variant: @variant3, order: order3)
      @orders << order3.reload
    end

    it "should return a header row describing the report" do
      subject = GroupBuyReport.new [@order1]
      header = subject.header
      expect(header).to eq(["Supplier", "Product", "Unit Size", "Variant", "Weight",
                            "Total Ordered", "Total Max"])
    end

    it "should provide the required variant and quantity information in a table" do
      subject = GroupBuyReport.new @orders

      table = subject.table

      line_items = @orders.map(&:line_items).flatten.select{ |li|
        li.product.supplier == @supplier1 && li.variant == @variant1
      }

      sum_quantities = line_items.map(&:quantity).sum
      sum_max_quantities = line_items.map { |li| li.max_quantity || 0 }.sum

      expect(table[0]).to eq([@variant1.product.supplier.name, @variant1.product.name, "UNITSIZE",
                              @variant1.options_text, @variant1.weight, sum_quantities, sum_max_quantities])
    end

    it "should return a table wherein each rows contains the same number of columns as the heading" do
      subject = GroupBuyReport.new @orders

      table = subject.table
      columns = subject.header.length

      table.each do |r|
        expect(r.length).to eq(columns)
      end
    end

    it "should split and group line items from multiple suppliers and of multiple variants" do
      subject = GroupBuyReport.new @orders

      table_row_objects = subject.variants_and_quantities

      variant_rows = table_row_objects.select { |r|
        r.instance_of?(OpenFoodNetwork::GroupBuyVariantRow)
      }
      product_rows = table_row_objects.select { |r|
        r.instance_of?(OpenFoodNetwork::GroupBuyProductRow)
      }

      supplier_groups = variant_rows.group_by { |r| r.variant.product.supplier }
      variant_groups = variant_rows.group_by(&:variant)
      product_groups = product_rows.group_by(&:product)

      expect(supplier_groups.length).to eq(2)
      expect(variant_groups.length).to eq(3)
      expect(product_groups.length).to eq(3)
    end
  end
end
