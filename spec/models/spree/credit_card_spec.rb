require 'spec_helper'

module Spree
  describe CreditCard do
    describe "setting default credit card for a user" do
      let(:user) { create(:user) }
      let(:onetime_card_attrs) do
        { user: user, gateway_payment_profile_id: "tok_1EY..." }
      end
      let(:stored_card_attrs) do
        {
          user: user,
          gateway_customer_profile_id: "cus_F2T...",
          gateway_payment_profile_id: "card_1EY..."
        }
      end
      let(:stored_default_card_attrs) do
        stored_card_attrs.merge(is_default: true)
      end

      context "when a card is already set as the default" do
        let!(:card1) { create(:credit_card, stored_default_card_attrs) }

        context "and I create a new card" do
          context "without specifying it as the default" do
            let!(:card2) { create(:credit_card, stored_card_attrs) }

            it "keeps the existing default" do
              expect(card1.reload.is_default).to be true
              expect(card2.reload.is_default).to be false
            end
          end

          context "and I specify it as the default" do
            let!(:card2) { create(:credit_card, stored_default_card_attrs) }

            it "switches the default to the new card" do
              expect(card1.reload.is_default).to be false
              expect(card2.reload.is_default).to be true
            end
          end
        end

        context "and I update another card" do
          let!(:card2) { create(:credit_card, user: user) }

          context "without specifying it as the default" do
            it "keeps the existing default" do
              card2.update!(stored_card_attrs)

              expect(card1.reload.is_default).to be true
              expect(card2.reload.is_default).to be false
            end
          end

          context "and I specify it as the default" do
            it "switches the default to the updated card" do
              card2.update!(stored_default_card_attrs)

              expect(card1.reload.is_default).to be false
              expect(card2.reload.is_default).to be true
            end
          end
        end
      end

      context "when no card is currently set as the default for a user" do
        context "and I create a new card" do
          context "without specifying it as the default" do
            let!(:card1) { create(:credit_card, stored_card_attrs) }

            it "sets it as the default anyway" do
              expect(card1.reload.is_default).to be true
            end
          end

          context "and I specify it as the default" do
            let!(:card1) { create(:credit_card, stored_default_card_attrs) }

            it "sets it as the default" do
              expect(card1.reload.is_default).to be true
            end
          end
        end

        context "and the checkout creates a card" do
          let!(:card1) { create(:credit_card, onetime_card_attrs) }
          let(:store_card_profile_attrs) {
            {
              cc_type: "visa",
              gateway_customer_profile_id: "cus_FH9HflKAJw6Kxy",
              gateway_payment_profile_id: "card_1EmayNBZvgSKc1B2wctIzzoh"
            }
          }

          it "doesn't set a one-time card as the default" do
            expect(card1.reload.is_default).to be false
          end

          it "sets a re-usable card as the default" do
            # The checkout first creates a one-time card and then converts it
            # to a re-usable card.
            # This imitates Stripe::ProfileStorer.
            card1.update!(store_card_profile_attrs)
            expect(card1.reload.is_default).to be true
          end
        end
      end
    end
  end
end
