require 'open_food_network/standing_order_summarizer'

module OpenFoodNetwork
  describe StandingOrderSummarizer do
    let(:order) { create(:order) }
    let(:summarizer) { OpenFoodNetwork::StandingOrderSummarizer.new }

    describe "#summary_for" do
      let(:order) { double(:order, distributor_id: 123) }

      context "when a summary for the order's distributor doesn't already exist" do
        it "initializes a new summary object, and returns it" do
          expect(summarizer.instance_variable_get(:@summaries).count).to be 0
          summary = summarizer.send(:summary_for, order)
          expect(summary.shop_id).to be 123
          expect(summarizer.instance_variable_get(:@summaries).count).to be 1
        end
      end

      context "when a summary for the order's distributor already exists" do
        let(:summary) { double(:summary) }

        before do
          summarizer.instance_variable_set(:@summaries, { 123 => summary })
        end

        it "returns the existing summary object" do
          expect(summarizer.instance_variable_get(:@summaries).count).to be 1
          expect(summarizer.send(:summary_for, order)).to eq summary
          expect(summarizer.instance_variable_get(:@summaries).count).to be 1
        end
      end
    end

    describe "recording events" do
      let(:order) { double(:order) }
      let(:summary) { double(:summary) }
      before { allow(summarizer).to receive(:summary_for).with(order) { summary } }

      describe "#record_order" do
        it "requests a summary for the order and calls #record_order on it" do
          expect(summary).to receive(:record_order).with(order).once
          summarizer.record_order(order)
        end
      end

      describe "#record_success" do
        it "requests a summary for the order and calls #record_success on it" do
          expect(summary).to receive(:record_success).with(order).once
          summarizer.record_success(order)
        end
      end

      describe "#record_issue" do
        it "requests a summary for the order and calls #record_issue on it" do
          expect(summary).to receive(:record_issue).with(:type, order, "message").once
          summarizer.record_issue(:type, order, "message")
        end
      end

      describe "#record_and_log_error" do
        before do
          allow(order).to receive(:number) { "123" }
        end

        context "when errors exist on the order" do
          before do
            allow(order).to receive(:errors) { double(:errors, any?: true, full_messages: ["Some error"]) }
          end

          it "sends error info to the rails logger and calls #record_issue on itself with an error message" do
            expect(Rails.logger).to receive(:info)
            expect(summarizer).to receive(:record_issue).with(:processing, order, "Errors: Some error")
            summarizer.record_and_log_error(:processing, order)
          end
        end

        context "when no errors exist on the order" do
          before do
            allow(order).to receive(:errors) { double(:errors, any?: false) }
          end

          it "falls back to calling record_issue" do
            expect(Rails.logger).to_not receive(:info)
            expect(summarizer).to receive(:record_issue).with(:processing, order)
            summarizer.record_and_log_error(:processing, order)
          end
        end
      end
    end

    describe "#send_placement_summary_emails" do
      let(:summary1) { double(:summary) }
      let(:summary2) { double(:summary) }
      let(:summaries) { { 1 => summary1, 2 => summary2 } }
      let(:mail_mock) { double(:mail, deliver: true) }

      before do
        summarizer.instance_variable_set(:@summaries, summaries)
      end

      it "sends a placement summary email for each summary" do
        expect(StandingOrderMailer).to receive(:placement_summary_email).twice { mail_mock }
        summarizer.send_placement_summary_emails
      end
    end
  end
end
