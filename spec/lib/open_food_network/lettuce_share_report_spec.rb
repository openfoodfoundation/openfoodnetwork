require 'spec_helper'

require 'open_food_network/lettuce_share_report'

module OpenFoodNetwork
  describe LettuceShareReport do
    let(:user) { create(:user) }
    let(:report) { LettuceShareReport.new user, {}, true }
    let(:variant) { create(:variant) }

    describe "grower and method" do
      it "shows just the producer when there is no certification" do
        report.stub(:producer_name) { "Producer" }
        report.stub(:certification) { "" }

        report.send(:grower_and_method, variant).should == "Producer"
      end

      it "shows producer and certification when a certification is present" do
        report.stub(:producer_name) { "Producer" }
        report.stub(:certification) { "Method" }

        report.send(:grower_and_method, variant).should == "Producer (Method)"
      end
    end

    describe "gst" do
      it "handles tax category without rates" do
        report.send(:gst, variant).should == 0
      end
    end

    describe "table" do
      it "handles no items" do
        report.table.should eq []
      end

      describe "lists" do
        let(:variant2) { create(:variant) }
        let(:variant3) { create(:variant) }
        let(:variant4) { create(:variant, on_hand: 0, on_demand: true) }
        let(:hub_address) { create(:address, :address1 => "distributor address", :city => 'The Shire', :zipcode => "1234") }
        let(:hub) { create(:distributor_enterprise, :address => hub_address) }
        let(:variant2_override) { create(:variant_override, hub: hub, variant: variant2) }
        let(:variant3_override) { create(:variant_override, hub: hub, variant: variant3, count_on_hand: 0) }

        it "all items" do
          report.stub(:child_variants) { Spree::Variant.where(id: [variant, variant2, variant3]) }
          report.table.count.should eq 3
        end

        it "only available items" do
          variant.on_hand = 0
          report.stub(:child_variants) { Spree::Variant.where(id: [variant, variant2, variant3, variant4]) }
          report.table.count.should eq 3
        end

        it "only available items considering overrides" do
          create(:exchange, incoming: false, receiver_id: hub.id, variants: [variant, variant2, variant3])
          # create the overrides
          variant2_override
          variant3_override
          report.stub(:child_variants) { Spree::Variant.where(id: [variant, variant2, variant3]) }
          report.stub(:params) { {distributor_id: hub.id} }
          rows = report.table
          rows.count.should eq 2
          rows.map{ |row| row[0] }.should include variant.product.name, variant2.product.name
        end

      end
    end
  end
end
