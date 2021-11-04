# frozen_string_literal: true

require 'spec_helper'

describe Spree::User do
  include OpenFoodNetwork::EmailHelper

  describe "associations" do
    it { is_expected.to have_many(:owned_enterprises) }

    describe "addresses" do
      let(:user) { create(:user, bill_address: create(:address)) }

      context "updating addresses via nested attributes" do
        it 'updates billing address with new address' do
          old_bill_address = user.bill_address
          new_bill_address = create(:address, firstname: 'abc')

          user.update(bill_address_attributes: new_bill_address.dup.attributes.merge('id' => old_bill_address.id).except!(
            'created_at', 'updated_at'
          ))

          expect(user.bill_address.id).to eq old_bill_address.id
          expect(user.bill_address.firstname).to eq new_bill_address.firstname
        end

        it 'creates new shipping address' do
          new_ship_address = create(:address, firstname: 'abc')

          user.update(ship_address_attributes: new_ship_address.dup.attributes.except!(
            'created_at', 'updated_at'
          ))

          expect(user.ship_address.id).not_to eq new_ship_address.id
          expect(user.ship_address.firstname).to eq new_ship_address.firstname
        end
      end
    end

    describe "enterprise ownership" do
      let(:u1) { create(:user, enterprise_limit: 2) }
      let(:u2) { create(:user, enterprise_limit: 1) }
      let!(:e1) { create(:enterprise, owner: u1) }
      let!(:e2) { create(:enterprise, owner: u1) }

      it "provides access to owned enterprises" do
        expect(u1.owned_enterprises.reload).to include e1, e2
      end

      it "enforces the limit on the number of enterprise owned" do
        expect(u2.owned_enterprises.reload).to eq []
        u2.owned_enterprises << e1
        expect { u2.save! }.to_not raise_error
        expect do
          u2.owned_enterprises << e2
          u2.save!
        end.to raise_error ActiveRecord::RecordInvalid,
                           "Validation failed: #{u2.email} is not permitted to own any more enterprises (limit is 1)."
      end
    end

    describe "group ownership" do
      let(:u1) { create(:user) }
      let(:u2) { create(:user) }
      let!(:g1) { create(:enterprise_group, owner: u1) }
      let!(:g2) { create(:enterprise_group, owner: u1) }
      let!(:g3) { create(:enterprise_group, owner: u2) }

      it "provides access to owned groups" do
        expect(u1.owned_groups.reload).to match_array([g1, g2])
        expect(u2.owned_groups.reload).to match_array([g3])
      end
    end

    it "loads a user's customer representation at a particular enterprise" do
      u = create(:user)
      e = create(:enterprise)
      c = create(:customer, user: u, enterprise: e)

      expect(u.customer_of(e)).to eq(c)
    end
  end

  context "#create" do
    it "should send a confirmation email" do
      setup_email

      performing_deliveries do
        expect do
          create(:user, email: 'new_user@example.com', confirmation_sent_at: nil, confirmed_at: nil)
        end.to enqueue_job ActionMailer::DeliveryJob
      end

      expect(enqueued_jobs.last.to_s).to match "confirmation_instructions"
    end

    context "with the the same email as existing customers" do
      let(:email) { generate(:random_email) }
      let(:enterprise1) { create(:enterprise) }
      let(:enterprise2) { create(:enterprise) }
      let!(:customer1) { create(:customer, user: nil, email: email, enterprise: enterprise1) }
      let!(:customer2) { create(:customer, user: nil, email: email, enterprise: enterprise2) }
      let!(:user) { create(:user, email: email) }

      it "should associate these customers with the created user" do
        expect(user.customers.reload).to include customer1, customer2
        expect(user.customer_of(enterprise1)).to be_truthy
        expect(user.customer_of(enterprise2)).to be_truthy
      end
    end
  end

  context "confirming email" do
    it "should send a welcome email" do
      setup_email

      expect do
        create(:user, confirmed_at: nil).confirm
      end.to enqueue_job ActionMailer::DeliveryJob

      expect(enqueued_jobs.last.to_s).to match "signup_confirmation"
    end
  end

  describe "known_users" do
    let!(:u1) { create(:user) }
    let!(:u2) { create(:user) }
    let!(:u3) { create(:user) }
    let!(:e1) { create(:enterprise, owner: u1, users: [u1, u2]) }

    describe "as an enterprise user" do
      it "returns a list of users which manage shared enterprises" do
        expect(u1.known_users).to include u1, u2
        expect(u1.known_users).to_not include u3
        expect(u2.known_users).to include u1, u2
        expect(u2.known_users).to_not include u3
        expect(u3.known_users).to_not include u1, u2, u3
      end
    end

    describe "as admin" do
      let(:admin) { create(:admin_user) }

      it "returns all users" do
        expect(admin.known_users).to include u1, u2, u3
      end
    end
  end

  describe "default_card" do
    let(:user) { create(:user) }

    context "when the user has no credit cards" do
      it "returns nil" do
        expect(user.default_card).to be nil
      end
    end

    context "when the user has one credit card" do
      let!(:card) { create(:stored_credit_card, user: user) }

      it "should be assigned as the default and be returned" do
        expect(card.reload.is_default).to be true
        expect(user.default_card.id).to be card.id
      end
    end

    context "when the user has more than one card" do
      let!(:non_default_card) { create(:stored_credit_card, user: user) }
      let!(:default_card) { create(:stored_credit_card, user: user, is_default: true) }

      it "returns the card which is specified as the default" do
        expect(user.default_card.id).to be default_card.id
      end
    end
  end

  describe '#admin?' do
    it 'returns true when the user has an admin spree role' do
      expect(create(:admin_user).admin?).to be_truthy
    end

    it 'returns false when the user does not have an admin spree role' do
      expect(create(:user).admin?).to eq(false)
    end
  end

  context '#destroy' do
    it 'can not delete if it has completed orders' do
      order = build(:order, completed_at: Time.zone.now)
      order.save
      user = order.user

      expect { user.destroy }.to raise_exception(Spree::User::DestroyWithOrdersError)
    end
  end

  describe "#flipper_id" do
    it "provides a unique id" do
      user = Spree::User.new(id: 42)
      expect(user.flipper_id).to eq "Spree::User;42"
    end
  end

  describe "#from_omniauth" do
    let(:auth) { double(:auth, provider: "openid_connect", uid: "user@email.com") }

    context "a valid email address" do
      let(:email) { "user@email.com" }

      it "creates a user without errors" do
        allow(auth).to receive_message_chain(:info, :email).and_return "user@email.com"
        user = Spree::User.from_omniauth(auth)
        expect(user.errors.present?).to be false
        expect(user.confirmed?).to be true
      end
    end

    context "an invalid email address" do
      it "raises an error" do
        allow(auth).to receive_message_chain(:info, :email).and_return "notanemailaddress"
        user = Spree::User.from_omniauth(auth)
        expect(user.errors.present?).to be true
      end
    end
  end
end
