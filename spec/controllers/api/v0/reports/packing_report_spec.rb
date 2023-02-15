# frozen_string_literal: true

require "spec_helper"

describe Api::V0::ReportsController, type: :controller do
  let(:params) {
    {
      report_type: 'packing',
      # rspec seems to remove empty values to setting something dummy so the
      # default_params will not overwritting this params
      fields_to_hide: [:none],
      q: { order_created_at_lt: Time.zone.now }
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

    results
  end

  def distributor_report_row(line_item)
    {
      "hub" => line_item.order.distributor.name,
      "customer_code" => line_item.order.customer&.code,
      "supplier" => line_item.product.supplier.name,
      "product" => line_item.product.name,
      "variant" => line_item.full_name,
      "quantity" => line_item.quantity,
      "price" => (line_item.quantity * line_item.price).to_s,
      "temp_controlled" => line_item.product.shipping_category&.temperature_controlled
    }.
      merge(dimensions(line_item)).
      merge(contacts(line_item.order.bill_address))
  end

  def supplier_report_row(line_item)
    {
      "hub" => line_item.order.distributor.name,
      'customer_code' => '< Hidden >',
      'first_name' => '< Hidden >',
      'last_name' => '< Hidden >',
      'phone' => '< Hidden >',
      "supplier" => line_item.product.supplier.name,
      "product" => line_item.product.name,
      "variant" => line_item.full_name,
      "quantity" => line_item.quantity,
      "price" => (line_item.quantity * line_item.price).to_s,
      "temp_controlled" => line_item.product.shipping_category&.temperature_controlled
    }.merge(dimensions(line_item))
  end

  def dimensions(line_item)
    {
      "weight" => line_item.weight.to_s,
      "height" => line_item.height.to_s,
      "width" => line_item.width.to_s,
      "depth" => line_item.depth.to_s
    }
  end

  def contacts(bill_address)
    {
      "first_name" => bill_address.firstname,
      "last_name" => bill_address.lastname,
      "phone" => bill_address.phone,
    }
  end
end
