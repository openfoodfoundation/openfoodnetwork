# frozen_string_literal: false

RSpec.describe Spree::CreditCard do
  let(:valid_credit_card_attributes) {
    {
      number: '4111111111111111',
      verification_value: '123',
      month: 12,
      year: Time.zone.now.year + 1
    }
  }

  describe "original specs from Spree" do
    def self.payment_states
      Spree::Payment.state_machine.states.keys
    end

    def stub_rails_env(environment)
      allow(Rails).to receive_messages(env: ActiveSupport::StringInquirer.new(environment))
    end

    let(:credit_card) { described_class.new }

    context "#valid?" do
      it "should validate presence of number" do
        credit_card.attributes = valid_credit_card_attributes.except(:number)
        expect(credit_card).not_to be_valid
        expect(credit_card.errors[:number]).to eq ["can't be blank"]
      end

      it "should validate presence of security code" do
        credit_card.attributes = valid_credit_card_attributes.except(:verification_value)
        expect(credit_card).not_to be_valid
        expect(credit_card.errors[:verification_value]).to eq ["can't be blank"]
      end

      it "should validate expiration is not in the past" do
        credit_card.month = 1.month.ago.month
        credit_card.year = 1.month.ago.year
        expect(credit_card).not_to be_valid
        expect(credit_card.errors[:base]).to eq ["has expired"]
      end

      it "does not run expiration in the past validation if month is not set" do
        credit_card.month = nil
        credit_card.year = Time.zone.now.year
        expect(credit_card).not_to be_valid
        expect(credit_card.errors[:base]).to be_blank
      end

      it "does not run expiration in the past validation if year is not set" do
        credit_card.month = Time.zone.now.month
        credit_card.year = nil
        expect(credit_card).not_to be_valid
        expect(credit_card.errors[:base]).to be_blank
      end

      it "does not run expiration in the past validation if year and month are empty" do
        credit_card.year = ""
        credit_card.month = ""
        expect(credit_card).not_to be_valid
        expect(credit_card.errors[:card]).to be_blank
      end

      it "should only validate on create" do
        credit_card.attributes = valid_credit_card_attributes
        credit_card.save
        expect(credit_card).to be_valid
      end
    end

    context "#save" do
      before do
        credit_card.attributes = valid_credit_card_attributes
        credit_card.save!
      end

      let!(:persisted_card) { described_class.find(credit_card.id) }

      it "should not actually store the number" do
        expect(persisted_card.number).to be_blank
      end

      it "should not actually store the security code" do
        expect(persisted_card.verification_value).to be_blank
      end
    end

    context "#number=" do
      it "should strip non-numeric characters from card input" do
        credit_card.number = "6011000990139424"
        expect(credit_card.number).to eq "6011000990139424"

        credit_card.number = "  6011-0009-9013-9424  "
        expect(credit_card.number).to eq "6011000990139424"
      end

      it "should not raise an exception on non-string input" do
        credit_card.number = ({})
        expect(credit_card.number).to be_nil
      end
    end

    context "#associations" do
      it "should be able to access its payments" do
        expect { credit_card.payments.to_a }.not_to raise_error
      end
    end

    context "#to_active_merchant" do
      before do
        credit_card.number = "4111111111111111"
        credit_card.year = Time.zone.now.year
        credit_card.month = Time.zone.now.month
        credit_card.first_name = "Bob"
        credit_card.last_name = "Boblaw"
        credit_card.verification_value = 123
      end

      it "converts to an ActiveMerchant::Billing::CreditCard object" do
        am_card = credit_card.to_active_merchant
        expect(am_card.number).to eq "4111111111111111"
        expect(am_card.year).to eq Time.zone.now.year
        expect(am_card.month).to eq Time.zone.now.month
        expect(am_card.first_name).to eq "Bob"
        am_card.last_name = "Boblaw"
        expect(am_card.verification_value).to eq 123
      end
    end
  end

  describe "formatting the card type for ActiveMerchant" do
    context "#cc_type=" do
      let(:credit_card) { build(:credit_card) }

      it "converts the card type format" do
        credit_card.cc_type = 'mastercard'
        expect(credit_card.cc_type).to eq 'master'

        credit_card.cc_type = 'maestro'
        expect(credit_card.cc_type).to eq 'master'

        credit_card.cc_type = 'amex'
        expect(credit_card.cc_type).to eq 'american_express'

        credit_card.cc_type = 'dinersclub'
        expect(credit_card.cc_type).to eq 'diners_club'

        credit_card.cc_type = 'some_outlandish_cc_type'
        expect(credit_card.cc_type).to eq 'some_outlandish_cc_type'
      end
    end

    context "on save" do
      it "converts the card type format" do
        expect_any_instance_of(described_class).to receive(:reformat_card_type!).
          at_least(:once).and_call_original

        credit_card = described_class.create(
          valid_credit_card_attributes.merge(cc_type: "Master Card")
        )

        expect(credit_card.cc_type).to eq "master"
      end
    end
  end

  describe "setting default credit card for a user" do
    let(:user) { create(:user) }
    let(:onetime_card_attrs) do
      { user:, gateway_payment_profile_id: "tok_1EY..." }
    end
    let(:stored_card_attrs) do
      {
        user:,
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
        let!(:card2) { create(:credit_card, user:) }

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
