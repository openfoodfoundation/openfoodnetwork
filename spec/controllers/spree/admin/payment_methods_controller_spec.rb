# frozen_string_literal: true

require 'spec_helper'

module Spree
  class GatewayWithPassword < PaymentMethod
    preference :password, :string, default: "password"
  end

  describe Admin::PaymentMethodsController, type: :controller do
    let(:user) {
      create(:user, enterprises: [create(:distributor_enterprise)])
    }

    describe "#new" do
      before { allow(controller).to receive(:spree_current_user) { user } }

      it "allows to select from a range of payment gateways" do
        spree_get :new
        providers = assigns(:providers).map(&:to_s)

        expect(providers).to eq %w[
          Spree::Gateway::Bogus
          Spree::Gateway::BogusSimple
          Spree::Gateway::PayPalExpress
          Spree::PaymentMethod::Check
        ]
      end

      it "allows to select StripeSCA when configured" do
        allow(Spree::Config).to receive(:stripe_connect_enabled).and_return(true)

        spree_get :new
        providers = assigns(:providers).map(&:to_s)

        expect(providers).to include "Spree::Gateway::StripeSCA"
      end
    end

    describe "#edit" do
      let(:stripe) {
        create(
          :stripe_sca_payment_method,
          distributor_ids: [enterprise_id],
          preferred_enterprise_id: enterprise_id
        )
      }
      let(:enterprise_id) { user.enterprise_ids.first }

      before { allow(controller).to receive(:spree_current_user) { user } }

      it "shows the current gateway type even if not enabled" do
        allow(Spree::Config).to receive(:stripe_connect_enabled).and_return(false)

        spree_get :edit, id: stripe.id
        providers = assigns(:providers).map(&:to_s)

        expect(providers).to include "Spree::Gateway::StripeSCA"
      end
    end

    describe "#create and #update" do
      let!(:enterprise) { create(:distributor_enterprise, owner: user) }
      let(:payment_method) {
        GatewayWithPassword.create!(name: "Bogus", preferred_password: "haxme",
                                    distributor_ids: [enterprise.id])
      }
      let!(:user) { create(:user) }

      before { allow(controller).to receive(:spree_current_user) { user } }

      it "does not clear password on update" do
        expect(payment_method.preferred_password).to eq "haxme"
        spree_put :update, id: payment_method.id,
                           payment_method: {
                             type: payment_method.class.to_s,
                             preferred_password: ""
                           }
        expect(response).to redirect_to spree.edit_admin_payment_method_path(payment_method)

        payment_method.reload
        expect(payment_method.preferred_password).to eq "haxme"
      end

      context "tries to save invalid payment" do
        it "doesn't break, responds nicely" do
          expect {
            spree_post :create, payment_method: { name: "", type: "Spree::Gateway::Bogus" }
          }.not_to raise_error
        end
      end

      it "can create a payment method of a valid type" do
        expect {
          spree_post :create,
                     payment_method: { name: "Test Method", type: "Spree::Gateway::Bogus",
                                       distributor_ids: [enterprise.id] }
        }.to change(Spree::PaymentMethod, :count).by(1)

        expect(response).to be_redirect
        expect(response).to redirect_to spree
          .edit_admin_payment_method_path(assigns(:payment_method))
      end

      it "can not create a payment method of an invalid type" do
        expect {
          spree_post :create,
                     payment_method: { name: "Invalid Payment Method", type: "Spree::InvalidType",
                                       distributor_ids: [enterprise.id] }
        }.to change(Spree::PaymentMethod, :count).by(0)

        expect(response).to be_redirect
        expect(response).to redirect_to spree.new_admin_payment_method_path
      end
    end

    describe "#update" do
      context "updating a payment method" do
        let!(:payment_method) { create(:payment_method, :flat_rate) }
        let(:params) {
          {
            id: payment_method.id,
            payment_method: {
              name: "Updated",
              description: "Updated",
              type: "Spree::PaymentMethod::Check",
              calculator_attributes: {
                id: payment_method.calculator.id,
                preferred_amount: 456,
              }
            }
          }
        }

        before { controller_login_as_admin }

        it "updates the payment method" do
          spree_post :update, params
          payment_method.reload

          expect(payment_method.name).to eq "Updated"
          expect(payment_method.description).to eq "Updated"
          expect(payment_method.calculator.preferred_amount).to eq 456
        end

        context "when the given payment method type does not match" do
          let(:params) {
            {
              id: payment_method.id,
              payment_method: {
                type: "Spree::Gateway::Bogus"
              }
            }
          }

          it "updates the payment method type" do
            spree_post :update, params

            expect(PaymentMethod.find(payment_method.id).type).to eq "Spree::Gateway::Bogus"
          end
        end
      end

      context "on a StripeSCA payment method" do
        let!(:user) { create(:user, enterprise_limit: 2) }
        let!(:enterprise1) { create(:distributor_enterprise, owner: user) }
        let!(:enterprise2) { create(:distributor_enterprise, owner: create(:user)) }
        let!(:payment_method) {
          create(
            :stripe_sca_payment_method,
            distributor_ids: [enterprise1.id, enterprise2.id],
            preferred_enterprise_id: enterprise2.id
          )
        }

        before { allow(controller).to receive(:spree_current_user) { user } }

        context "when an attempt is made to change " \
                "the stripe account holder (preferred_enterprise_id)" do
          let(:params) {
            {
              id: payment_method.id,
              payment_method: {
                type: "Spree::Gateway::StripeSCA",
                preferred_enterprise_id: enterprise1.id
              }
            }
          }

          context "as a user that does not manage the existing stripe account holder" do
            it "prevents the stripe account holder from being updated" do
              spree_put :update, params
              expect(payment_method.reload.preferred_enterprise_id).to eq enterprise2.id
            end
          end

          context "as a user that manages the existing stripe account holder" do
            before { enterprise2.update!(owner_id: user.id) }

            it "allows the stripe account holder to be updated" do
              spree_put :update, params
              expect(payment_method.reload.preferred_enterprise_id).to eq enterprise1.id
            end

            context "when no enterprise is selected as the account holder" do
              before { payment_method.update_attribute(:preferred_enterprise_id, nil) }

              context "id not provided at all" do
                before { params[:payment_method].delete(:preferred_enterprise_id) }

                it "does not save the payment method" do
                  spree_put :update, params
                  expect(response).to render_template :edit
                  expect(assigns(:payment_method).errors
                    .messages[:stripe_account_owner]).to include 'can\'t be blank'
                end
              end

              context "enterprise_id of 0" do
                before { params[:payment_method][:preferred_enterprise_id] = 0 }

                it "does not save the payment method" do
                  spree_put :update, params
                  expect(response).to render_template :edit
                  expect(assigns(:payment_method).errors
                    .messages[:stripe_account_owner]).to include 'can\'t be blank'
                end
              end
            end
          end
        end
      end
    end

    context "Requesting provider preference fields" do
      let(:enterprise) { create(:distributor_enterprise) }
      let(:user) do
        new_user = create(:user, email: 'enterprise@hub.com', password: 'blahblah',
                                 password_confirmation: 'blahblah', )
        # for some reason unbeknown to me, this new user gets admin permissions by default.
        new_user.spree_roles = []
        new_user.enterprise_roles.build(enterprise: enterprise).save
        new_user.save
        new_user
      end

      before do
        allow(controller).to receive_messages spree_current_user: user
      end

      context "on an existing payment method" do
        let(:payment_method) { create(:payment_method) }

        context "where I have permission" do
          before do
            payment_method.distributors << user.enterprises.is_distributor.first
          end

          context "without an altered provider type" do
            it "renders provider settings with same payment method" do
              spree_get :show_provider_preferences,
                        pm_id: payment_method.id,
                        provider_type: "Spree::PaymentMethod::Check"
              expect(assigns(:payment_method)).to eq payment_method
              expect(response).to render_template partial: '_provider_settings'
            end
          end

          context "with an altered provider type" do
            it "renders provider settings with a different payment method" do
              spree_get :show_provider_preferences,
                        pm_id: payment_method.id,
                        provider_type: "Spree::Gateway::Bogus"
              expect(assigns(:payment_method)).not_to eq payment_method
              expect(response).to render_template partial: '_provider_settings'
            end
          end
        end

        context "where I do not have permission" do
          before do
            payment_method.distributors = []
          end

          it "renders unauthorised" do
            spree_get :show_provider_preferences,
                      pm_id: payment_method.id,
                      provider_type: "Spree::PaymentMethod::Check"
            expect(assigns(:payment_method)).to eq payment_method
            expect(flash[:error]).to eq "Authorization Failure"
          end
        end
      end

      context "on a new payment method" do
        it "renders provider settings with a new payment method of type" do
          spree_get :show_provider_preferences,
                    pm_id: "",
                    provider_type: "Spree::Gateway::Bogus"
          expect(assigns(:payment_method)).to be_a_new Spree::Gateway::Bogus
          expect(response).to render_template partial: '_provider_settings'
        end
      end
    end
  end
end
