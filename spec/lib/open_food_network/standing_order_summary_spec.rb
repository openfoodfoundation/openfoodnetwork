require 'open_food_network/standing_order_summary'

module OpenFoodNetwork
  describe StandingOrderSummary do
    let(:summary) { OpenFoodNetwork::StandingOrderSummary.new(123) }

    describe "#initialize" do
      it "initializes instance variables: shop_id, order_count, success_count and issues" do
        expect(summary.shop_id).to be 123
        expect(summary.order_count).to be 0
        expect(summary.success_count).to be 0
        expect(summary.issues).to be_a Hash
      end
    end

    describe "#record_order" do
      let(:order) { double(:order, id: 37) }
      it "adds the order id to the order_ids array" do
        summary.record_order(order)
        expect(summary.instance_variable_get(:@order_ids)).to eq [order.id]
      end
    end

    describe "#record_success" do
      let(:order) { double(:order, id: 37) }
      it "adds the order id to the success_ids array" do
        summary.record_success(order)
        expect(summary.instance_variable_get(:@success_ids)).to eq [order.id]
      end
    end

    describe "#record_issue" do
      let(:order) { double(:order, id: 1) }

      context "when no issues of the same type have been recorded yet" do
        it "adds a new type to the issues hash, and stores a new issue against it" do
          summary.record_issue(:some_type, order, "message")
          expect(summary.issues.keys).to include :some_type
          expect(summary.issues[:some_type][order.id]).to eq "message"
        end
      end

      context "when an issue of the same type has already been recorded" do
        let(:existing_issue) { double(:existing_issue) }

        before { summary.issues[:some_type] = [existing_issue] }

        it "stores a new issue against the existing type" do
          summary.record_issue(:some_type, order, "message")
          expect(summary.issues[:some_type]).to include existing_issue
          expect(summary.issues[:some_type][order.id]).to eq "message"
        end
      end
    end

    describe "#order_count" do
      let(:order_ids) { [1,2,3,4,5,6,7] }
      it "counts the number of items in the order_ids instance_variable" do
        summary.instance_variable_set(:@order_ids, order_ids)
        expect(summary.order_count).to be 7
      end
    end

    describe "#success_count" do
      let(:success_ids) { [1,2,3,4,5,6,7] }
      it "counts the number of items in the success_ids instance_variable" do
        summary.instance_variable_set(:@success_ids, success_ids)
        expect(summary.success_count).to be 7
      end
    end

    describe "#lissue_count" do
      let(:order_ids) { [1,3,5,7,9] }
      let(:success_ids) { [1,2,3,4,5] }

      it "counts the number of items in order_ids that are not in success_ids" do
        summary.instance_variable_set(:@order_ids, order_ids)
        summary.instance_variable_set(:@success_ids, success_ids)
        expect(summary.issue_count).to be 2 # 7 & 9
      end
    end
  end
end
