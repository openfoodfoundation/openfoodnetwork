# frozen_string_literal: true

require "spec_helper"

describe Api::V0::ReportsController, type: :controller do
  let(:params) {
    {
      report_type: 'packing',
      q: { created_at_lt: Time.zone.now }
    }
  }

  before do
    allow(controller).to receive(:spree_current_user) { current_user }
    order.finalize!
  end

  describe "packing report" do
    context "as an enterprise user with full order permissions (distributor)" do
      let!(:distributor) { create(:distributor_enterprise) }
      let!(:order) { create(:completed_order_with_totals, distributor: distributor) }
      let(:current_user) { distributor.owner }

      it "renders results" do
        api_get :show, params

        expect(response.status).to eq 200
        expect(json_response[:data]).to match_array report_output(order, "distributor")
      end
    end

    context "as an enterprise user with partial order permissions (supplier with P-OC)" do
      let!(:order) { create(:completed_order_with_totals) }
      let(:supplier) { order.line_items.first.product.supplier }
      let(:current_user) { supplier.owner }
      let!(:perms) {
        create(:enterprise_relationship, parent: supplier, child: order.distributor,
                                         permissions_list: [:add_to_order_cycle])
      }

      it "renders results" do
        api_get :show, params

        expect(response.status).to eq 200
        expect(json_response[:data]).to match_array report_output(order, "supplier")
      end
    end
  end

  private

  def report_output(order, user_type)
    results = []

    order.line_items.each do |line_item|
      results << __send__("#{user_type}_report_row", line_item)
    end

    results << summary_row(order)
  end

  def distributor_report_row(line_item)
    {
      "hub" => line_item.order.distributor.name,
      "customer_code" => line_item.order.customer&.code,
      "first_name" => line_item.order.bill_address.firstname,
      "last_name" => line_item.order.bill_address.lastname,
      "supplier" => line_item.product.supplier.name,
      "product" => line_item.product.name,
      "variant" => line_item.full_name,
      "quantity" => line_item.quantity,
      "temp_controlled" =>
        line_item.product.shipping_category&.temperature_controlled ? I18n.t(:yes) : I18n.t(:no)
    }
  end

  def supplier_report_row(line_item)
    {
      "hub" => line_item.order.distributor.name,
      "customer_code" => I18n.t("hidden_field", scope: i18n_scope),
      "first_name" => I18n.t("hidden_field", scope: i18n_scope),
      "last_name" => I18n.t("hidden_field", scope: i18n_scope),
      "supplier" => line_item.product.supplier.name,
      "product" => line_item.product.name,
      "variant" => line_item.full_name,
      "quantity" => line_item.quantity,
      "temp_controlled" =>
        line_item.product.shipping_category&.temperature_controlled ? I18n.t(:yes) : I18n.t(:no)
    }
  end

  def summary_row(order)
    {
      "hub" => "",
      "customer_code" => "",
      "first_name" => "",
      "last_name" => "",
      "supplier" => "",
      "product" => I18n.t("total_items", scope: i18n_scope),
      "variant" => "",
      "quantity" => order.line_items.sum(&:quantity),
      "temp_controlled" => "",
    }
  end

  def i18n_scope
    "admin.reports"
  end
end
