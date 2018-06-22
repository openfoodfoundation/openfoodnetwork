require 'spec_helper'

module Spree
  describe CreditCard do
    describe "setting default credit card for a user" do
      let(:user) { create(:user) }

      context "when a card is already set as the default" do
        let!(:card1) { create(:credit_card, user: user, is_default: true) }

        context "and I create a new card" do
          let(:attrs) { { user: user } }
          let!(:card2) { create(:credit_card, attrs) }

          context "without specifying it as the default" do
            it "keeps the existing default" do
              expect(card1.reload.is_default).to be true
              expect(card2.reload.is_default).to be false
            end
          end

          context "and I specify it as the default" do
            let(:attrs) { { user: user, is_default: true } }

            it "switches the default to the new card" do
              expect(card1.reload.is_default).to be false
              expect(card2.reload.is_default).to be true
            end
          end
        end

        context "and I update another card" do
          let(:attrs) { { user: user } }
          let!(:card2) { create(:credit_card, user: user) }

          before do
            card2.update_attributes!(attrs)
          end

          context "without specifying it as the default" do
            it "keeps the existing default" do
              expect(card1.reload.is_default).to be true
              expect(card2.reload.is_default).to be false
            end
          end

          context "and I specify it as the default" do
            let(:attrs) { { user: user, is_default: true } }

            it "switches the default to the updated card" do
              expect(card1.reload.is_default).to be false
              expect(card2.reload.is_default).to be true
            end
          end
        end
      end

      context "when no card is currently set as the default for a user" do
        context "and I create a new card" do
          let(:attrs) { { user: user } }
          let!(:card1) { create(:credit_card, attrs) }

          context "without specifying it as the default" do
            it "sets it as the default anyway" do
              expect(card1.reload.is_default).to be true
            end
          end

          context "and I specify it as the default" do
            let(:attrs) { { user: user, is_default: true } }

            it "sets it as the default" do
              expect(card1.reload.is_default).to be true
            end
          end
        end
      end
    end
  end
end
