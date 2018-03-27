require 'open_food_network/lettuce_share_report'

module OpenFoodNetwork
  describe LettuceShareReport do
    let(:user) { create(:user) }
    let(:report) { LettuceShareReport.new user }
    let(:v) { create(:variant) }

    describe "grower and method" do
      it "shows just the producer when there is no certification" do
        allow(report).to receive(:producer_name) { "Producer" }
        allow(report).to receive(:certification) { "" }

        expect(report.send(:grower_and_method, v)).to eq("Producer")
      end

      it "shows producer and certification when a certification is present" do
        allow(report).to receive(:producer_name) { "Producer" }
        allow(report).to receive(:certification) { "Method" }

        expect(report.send(:grower_and_method, v)).to eq("Producer (Method)")
      end
    end

    describe "gst" do
      it "handles tax category without rates" do
        expect(report.send(:gst, v)).to eq(0)
      end
    end

    describe "table" do
      it "handles no items" do
        expect(report.send(:table)).to eq []
      end

      describe "lists" do
        let(:v2) { create(:variant) }
        let(:v3) { create(:variant) }
        let(:v4) { create(:variant, count_on_hand: 0, on_demand: true) }
        let(:hub_address) { create(:address, :address1 => "distributor address", :city => 'The Shire', :zipcode => "1234") }
        let(:hub) { create(:distributor_enterprise, :address => hub_address) }
        let(:v2o) { create(:variant_override, hub: hub, variant: v2) }
        let(:v3o) { create(:variant_override, hub: hub, variant: v3, count_on_hand: 0) }

        it "all items" do
          allow(report).to receive(:child_variants) { Spree::Variant.where(id: [v, v2, v3]) }
          expect(report.send(:table).count).to eq 3
        end

        it "only available items" do
          v.update_column(:count_on_hand, 0)
          allow(report).to receive(:child_variants) { Spree::Variant.where(id: [v, v2, v3, v4]) }
          expect(report.send(:table).count).to eq 3
        end

        it "only available items considering overrides" do
          create(:exchange, incoming: false, receiver_id: hub.id, variants: [v, v2, v3])
          # create the overrides
          v2o
          v3o
          allow(report).to receive(:child_variants) { Spree::Variant.where(id: [v, v2, v3]) }
          allow(report).to receive(:params) { {distributor_id: hub.id} }
          rows = report.send(:table)
          expect(rows.count).to eq 2
          expect(rows.map{ |row| row[0] }).to include v.product.name, v2.product.name
        end

      end
    end
  end
end
