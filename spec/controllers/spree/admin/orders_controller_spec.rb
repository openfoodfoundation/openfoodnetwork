require 'spec_helper'

describe Spree::Admin::OrdersController, type: :controller do
  include AuthenticationWorkflow

  context "updating an order with line items" do
    let!(:order) { create(:order) }
    let(:line_item) { create(:line_item) }
    before { login_as_admin }

    it "updates distribution charges" do
      order.line_items << line_item
      order.save
      Spree::Order.any_instance.should_receive(:update_distribution_charge!)
      spree_put :update, {
        id: order,
        order: {
          number: order.number,
          distributor_id: order.distributor_id,
          order_cycle_id: order.order_cycle_id,
          line_items_attributes: [
            {
              id: line_item.id,
              quantity: line_item.quantity
            }
          ]
        }
      }
    end
  end

  describe "#index" do
    context "as a regular user" do
      before { controller.stub spree_current_user: create_enterprise_user }

      it "should deny me access to the index action" do
        spree_get :index
        expect(response).to redirect_to spree.unauthorized_path
      end
    end

    context "as an enterprise user" do
      let!(:order) { create(:order_with_distributor) }

      before do
        controller.stub spree_current_user: order.distributor.owner
      end

      it "should allow access" do
        expect(response.status).to eq 200
      end
    end
  end

  describe "#invoice" do
    let!(:user) { create(:user) }
    let!(:enterprise_user) { create(:user) }
    let!(:order) { create(:order_with_distributor, bill_address: create(:address), ship_address: create(:address)) }
    let!(:distributor) { order.distributor }
    let(:params) { { id: order.number } }

    context "as a normal user" do
      before { controller.stub spree_current_user: user }

      it "should prevent me from sending order invoices" do
        spree_get :invoice, params
        expect(response).to redirect_to spree.unauthorized_path
      end
    end

    context "as an enterprise user" do
      context "which is not a manager of the distributor for an order" do
        before { controller.stub spree_current_user: user }
        it "should prevent me from sending order invoices" do
          spree_get :invoice, params
          expect(response).to redirect_to spree.unauthorized_path
        end
      end

      context "which is a manager of the distributor for an order" do
        before { controller.stub spree_current_user: distributor.owner }
        context "when the distributor's ABN has not been set" do
          before { distributor.update_attribute(:abn, "") }
          it "should allow me to send order invoices" do
            expect do
              spree_get :invoice, params
            end.to_not change{Spree::OrderMailer.deliveries.count}
            expect(response).to redirect_to spree.edit_admin_order_path(order)
            expect(flash[:error]).to eq "#{distributor.name} must have a valid ABN before invoices can be sent."
          end
        end

        context "when the distributor's ABN has been set" do
          before { distributor.update_attribute(:abn, "123") }
          before do
            Spree::MailMethod.create!(
              environment: Rails.env,
              preferred_mails_from: 'spree@example.com'
            )
          end
          it "should allow me to send order invoices" do
            expect do
              spree_get :invoice, params
            end.to change{Spree::OrderMailer.deliveries.count}.by(1)
            expect(response).to redirect_to spree.edit_admin_order_path(order)
          end
        end
      end
    end
  end

  describe "#print" do
    let!(:user) { create(:user) }
    let!(:enterprise_user) { create(:user) }
    let!(:order) { create(:order_with_distributor, bill_address: create(:address), ship_address: create(:address)) }
    let!(:distributor) { order.distributor }
    let(:params) { { id: order.number } }

    context "as a normal user" do
      before { controller.stub spree_current_user: user }

      it "should prevent me from sending order invoices" do
        spree_get :print, params
        expect(response).to redirect_to spree.unauthorized_path
      end
    end

    context "as an enterprise user" do
      context "which is not a manager of the distributor for an order" do
        before { controller.stub spree_current_user: user }
        it "should prevent me from sending order invoices" do
          spree_get :print, params
          expect(response).to redirect_to spree.unauthorized_path
        end
      end

      context "which is a manager of the distributor for an order" do
        before { controller.stub spree_current_user: distributor.owner }
        it "should allow me to send order invoices" do
          spree_get :print, params
          expect(response).to render_template :invoice
        end
      end
    end
  end
end
