# frozen_string_literal: true

require 'spec_helper'

module Admin
  describe CustomersController, type: :controller do
    include AuthenticationHelper

    describe "index" do
      let(:enterprise) { create(:distributor_enterprise) }
      let(:another_enterprise) { create(:distributor_enterprise) }

      context "html" do
        before do
          allow(controller).to receive(:spree_current_user) { enterprise.owner }
        end

        it "returns an empty @collection" do
          get :index, as: :html
          expect(assigns(:collection)).to eq []
        end
      end

      context "json" do
        let!(:customer) { create(:customer, enterprise: enterprise, created_manually: true) }

        context "where I manage the enterprise" do
          before do
            allow(controller).to receive(:spree_current_user) { enterprise.owner }
          end

          context "and enterprise_id is given in params" do
            let(:user){ enterprise.users.first }
            let(:customers){ Customer.visible.managed_by(user).where(enterprise_id: enterprise.id) }
            let(:params) { { format: :json, enterprise_id: enterprise.id } }

            it "scopes @collection to customers of that enterprise" do
              get :index, params: params
              expect(assigns(:collection)).to eq [customer]
            end

            it "serializes the data" do
              expect(ActiveModel::ArraySerializer).to receive(:new)
              get :index, params: params
            end

            it 'calls CustomersWithBalance' do
              customers_with_balance = instance_double(CustomersWithBalance)
              allow(CustomersWithBalance)
                .to receive(:new).with(customers) { customers_with_balance }

              expect(customers_with_balance).to receive(:query) { Customer.none }

              get :index, params: params
            end

            it 'serializes using CustomerWithBalanceSerializer' do
              expect(Api::Admin::CustomerWithBalanceSerializer).to receive(:new)

              get :index, params: params
            end

            context 'when the customer has no orders' do
              it 'includes the customer balance in the response' do
                get :index, params: params
                expect(json_response.first["balance"]).to eq("$0.00")
              end
            end

            context 'when the customer has complete orders' do
              let(:order) { create(:order, customer: customer, state: 'complete') }
              let!(:line_item) { create(:line_item, order: order, price: 10.0) }

              it 'includes the customer balance in the response' do
                order.update_order!
                get :index, params: params
                expect(json_response.first["balance"]).to eq("$-10.00")
              end
            end

            context 'when the customer has canceled orders' do
              let(:order) { create(:order, customer: customer) }
              let!(:variant) { create(:variant, price: 10.0) }

              before do
                allow_any_instance_of(Spree::Payment).to receive(:completed?).and_return(true)

                order.contents.add(variant)
                order.payments << create(:payment, order: order, amount: order.total)
                order.reload

                order.process_payments!
                order.update_attribute(:state, 'canceled')
              end

              it 'includes the customer balance in the response' do
                get :index, params: params
                expect(json_response.first["balance"]).to eq("$10.00")
              end
            end

            context 'when the customer has cart orders' do
              let(:order) { create(:order, customer: customer, state: 'cart') }
              let!(:line_item) { create(:line_item, order: order, price: 10.0) }

              it 'includes the customer balance in the response' do
                get :index, params: params
                expect(json_response.first["balance"]).to eq("$0.00")
              end
            end

            context 'when the customer has an order with a void payment' do
              let(:order) { create(:order_with_totals, customer: customer, state: 'complete') }
              let!(:payment) { create(:payment, order: order, amount: order.total) }

              before do
                allow_any_instance_of(Spree::Payment).to receive(:completed?).and_return(true)
                order.process_payments!

                payment.void_transaction!
              end

              it 'includes the customer balance in the response' do
                expect(order.payment_total).to eq(0)
                get :index, params: params
                expect(json_response.first["balance"]).to eq('$-10.00')
              end
            end
          end

          context "and enterprise_id is not given in params" do
            it "returns an empty collection" do
              get :index, as: :json
              expect(assigns(:collection)).to eq []
            end
          end
        end

        context "and I do not manage the enterprise" do
          before do
            allow(controller).to receive(:spree_current_user) { another_enterprise.owner }
          end

          it "returns an empty collection" do
            get :index, as: :json
            expect(assigns(:collection)).to eq []
          end
        end
      end
    end

    describe "update" do
      let(:enterprise) { create(:distributor_enterprise) }
      let(:another_enterprise) { create(:distributor_enterprise) }

      context "json" do
        let!(:customer) { create(:customer, enterprise: enterprise) }

        context "where I manage the customer's enterprise" do
          render_views

          before do
            allow(controller).to receive(:spree_current_user) { enterprise.owner }
          end

          it "allows me to update the customer" do
            spree_put :update, format: :json, id: customer.id,
                               customer: { email: 'new.email@gmail.com' }
            expect(JSON.parse(response.body)["id"]).to eq customer.id
            expect(assigns(:customer)).to eq customer
            expect(customer.reload.email).to eq 'new.email@gmail.com'
          end
        end

        context "where I don't manage the customer's enterprise" do
          before do
            allow(controller).to receive(:spree_current_user) { another_enterprise.owner }
          end

          it "prevents me from updating the customer" do
            spree_put :update, format: :json, id: customer.id,
                               customer: { email: 'new.email@gmail.com' }
            expect(response).to redirect_to unauthorized_path
            expect(assigns(:customer)).to eq nil
            expect(customer.email).to_not eq 'new.email@gmail.com'
          end
        end
      end
    end

    describe "create" do
      let(:enterprise) { create(:distributor_enterprise) }
      let(:another_enterprise) { create(:distributor_enterprise) }

      def create_customer(enterprise)
        spree_put :create, format: :json,
                           customer: { email: 'new@example.com', enterprise_id: enterprise.id }
      end

      context "json" do
        context "where I manage the customer's enterprise" do
          before do
            allow(controller).to receive(:spree_current_user) { enterprise.owner }
          end

          it "allows me to create the customer" do
            expect { create_customer enterprise }.to change(Customer, :count).by(1)
          end
        end

        context "where I don't manage the customer's enterprise" do
          before do
            allow(controller).to receive(:spree_current_user) { another_enterprise.owner }
          end

          it "prevents me from creating the customer" do
            expect { create_customer enterprise }.to change(Customer, :count).by(0)
          end
        end

        context "where I am the admin user" do
          before do
            allow(controller).to receive(:spree_current_user) { create(:admin_user) }
          end

          it "allows admins to create the customer" do
            expect { create_customer enterprise }.to change(Customer, :count).by(1)
          end
        end
      end
    end

    describe "show" do
      let(:enterprise) { create(:distributor_enterprise) }
      let(:another_enterprise) { create(:distributor_enterprise) }

      context "json" do
        let!(:customer) { create(:customer, enterprise: enterprise) }

        context "where I manage the customer's enterprise" do
          render_views

          before do
            allow(controller).to receive(:spree_current_user) { enterprise.owner }
          end

          it "renders the customer as json" do
            get :show, as: :json, params: { id: customer.id }
            expect(JSON.parse(response.body)["id"]).to eq customer.id
          end
        end

        context "where I don't manage the customer's enterprise" do
          before do
            allow(controller).to receive(:spree_current_user) { another_enterprise.owner }
          end

          it "prevents me from updating the customer" do
            get :show, as: :json, params: { id: customer.id }
            expect(response).to redirect_to unauthorized_path
          end
        end
      end
    end
  end
end
