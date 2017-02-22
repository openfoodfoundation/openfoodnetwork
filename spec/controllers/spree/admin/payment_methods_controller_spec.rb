require 'spec_helper'

describe Spree::Admin::PaymentMethodsController, type: :controller do
  describe "#update" do
    context "on a StripeConnect payment method" do
      let!(:user) { create(:user, enterprise_limit: 2) }
      let!(:enterprise1) { create(:distributor_enterprise, owner: user) }
      let!(:enterprise2) { create(:distributor_enterprise, owner: create(:user)) }
      let!(:payment_method) { create(:stripe_payment_method, distributor_ids: [enterprise1.id, enterprise2.id], preferred_enterprise_id: enterprise2.id) }

      before { allow(controller).to receive(:spree_current_user) { user } }

      context "when an attempt is made to change the stripe account holder (preferred_enterprise_id)" do
        let(:params) { { id: payment_method.id, payment_method: { type: "Spree::Gateway::StripeConnect", preferred_enterprise_id: enterprise1.id } } }

        context "as a user that does not manage the existing stripe account holder" do
          it "prevents the stripe account holder from being updated" do
            spree_put :update, params
            expect(payment_method.reload.preferred_enterprise_id).to eq enterprise2.id
          end
        end

        context "as a user that manages the existing stripe account holder" do
          before { enterprise2.update_attributes!(owner_id: user.id) }

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
                expect(assigns(:payment_method).errors.messages[:stripe_account_owner]).to include I18n.t(:error_required)
              end
            end

            context "enterprise_id of 0" do
              before { params[:payment_method][:preferred_enterprise_id] = 0 }

              it "does not save the payment method" do
                spree_put :update, params
                expect(response).to render_template :edit
                expect(assigns(:payment_method).errors.messages[:stripe_account_owner]).to include I18n.t(:error_required)
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
      new_user = create(:user, email: 'enterprise@hub.com', password: 'blahblah', :password_confirmation => 'blahblah', )
      new_user.spree_roles = [] # for some reason unbeknown to me, this new user gets admin permissions by default.
      new_user.enterprise_roles.build(enterprise: enterprise).save
      new_user.save
      new_user
    end

    before do
      controller.stub spree_current_user: user
    end

    context "on an existing payment method" do
      let(:payment_method) { create(:payment_method) }

      context "where I have permission" do
        before do
          payment_method.distributors << user.enterprises.is_distributor.first
        end

        context "without an altered provider type" do
          it "renders provider settings with same payment method" do
            spree_get :show_provider_preferences, {
              pm_id: payment_method.id,
              provider_type: "Spree::PaymentMethod::Check"
            }
            expect(assigns(:payment_method)).to eq payment_method
            expect(response).to render_template partial: '_provider_settings'
          end
        end

        context "with an altered provider type" do
          it "renders provider settings with a different payment method" do
            spree_get :show_provider_preferences, {
              pm_id: payment_method.id,
              provider_type: "Spree::Gateway::Bogus"
            }
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
          spree_get :show_provider_preferences, {
            pm_id: payment_method.id,
            provider_type: "Spree::PaymentMethod::Check"
          }
          expect(assigns(:payment_method)).to eq payment_method
          expect(flash[:error]).to eq "Authorization Failure"
        end
      end
    end

    context "on a new payment method" do
      it "renders provider settings with a new payment method of type" do
        spree_get :show_provider_preferences, {
          pm_id: "",
          provider_type: "Spree::Gateway::Bogus"
        }
        expect(assigns(:payment_method)).to be_a_new Spree::Gateway::Bogus
        expect(response).to render_template partial: '_provider_settings'
      end
    end
  end
end
