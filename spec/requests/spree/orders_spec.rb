# frozen_string_literal: true

RSpec.describe "Order print" do
  let(:user) { create(:user) }
  let(:distributor) { create(:distributor_enterprise) }
  let(:order) {
    create(:completed_order_with_totals, user:, distributor:)
  }

  describe "GET /orders/:id/print" do
    context "when the user is logged in and owns the order" do
      before { sign_in user }

      it "returns a PDF named after the order" do
        get print_order_path(order.number)

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq("application/pdf")
        expect(response.headers["Content-Disposition"]).to include("order-#{order.number}.pdf")
      end

      it "does not create an invoice" do
        expect { get print_order_path(order.number) }.not_to change { Invoice.count }
      end

      context "when the invoices feature is enabled", feature: :invoices do
        it "still does not create an invoice" do
          expect { get print_order_path(order.number) }.not_to change { Invoice.count }
        end
      end
    end

    context "when the user is not logged in" do
      it "redirects to login" do
        get print_order_path(order.number)

        expect(response).to redirect_to(%r|#/login|)
      end
    end

    context "when the order belongs to another user" do
      before { sign_in create(:user) }

      it "is not authorized" do
        get print_order_path(order.number)

        expect(response).not_to have_http_status(:ok)
      end
    end
  end
end
