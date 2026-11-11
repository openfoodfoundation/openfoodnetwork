# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Reports filter translation", swagger_doc: "v1.yaml" do
  def report_get(report_type, params = {})
    get "/api/v1/reports/#{report_type}",
        params:,
        headers: { "X-Api-Token" => "reports-filter-translation-token" }
  end

  let(:translation_hub_owner) { create(:user) }
  let!(:translation_hub) { create(:distributor_enterprise, owner: translation_hub_owner) }
  let!(:translation_producer) { create(:supplier_enterprise) }
  let!(:translation_order_cycle) do
    create(:simple_order_cycle, coordinator: translation_hub)
  end
  let(:completed_at_gt) { Time.zone.parse("2026-01-01 08:00").iso8601 }
  let(:completed_at_lt) { Time.zone.parse("2026-02-01 08:00").iso8601 }

  before do
    translation_hub_owner.update!(spree_api_key: "reports-filter-translation-token")
  end

  def translation_params(extra = {})
    extra.merge(order_cycle_id: translation_order_cycle.id)
  end

  it "constructs every report with unformatted JSON output" do
    [
      Reporting::Reports::Packing::Customer,
      Reporting::Reports::XeroInvoices::Summary,
      Reporting::Reports::Customers::Base,
      Reporting::Reports::ProductsAndInventory::AllProducts,
      Reporting::Reports::OrderCycleManagement::PaymentMethods,
      Reporting::Reports::EnterpriseFeeSummary::FeeSummary
    ].each do |report_class|
      allow(report_class).to receive(:new).and_call_original
    end

    report_get("packing", translation_params(report_subtype: "customer"))
    report_get("xero_invoices", translation_params(report_subtype: "summary"))
    report_get("customers", translation_params)
    report_get("products_and_inventory", translation_params(report_subtype: "all_products"))
    report_get("order_cycle_management",
               translation_params(report_subtype: "payment_methods"))
    report_get("enterprise_fee_summary", translation_params(report_subtype: "fee_summary"))

    [
      Reporting::Reports::Packing::Customer,
      Reporting::Reports::XeroInvoices::Summary,
      Reporting::Reports::Customers::Base,
      Reporting::Reports::ProductsAndInventory::AllProducts,
      Reporting::Reports::OrderCycleManagement::PaymentMethods,
      Reporting::Reports::EnterpriseFeeSummary::FeeSummary
    ].each do |report_class|
      expect(report_class).to have_received(:new).with(
        translation_hub_owner, hash_including(report_format: "json")
      )
    end
  end

  it "maps packing filters to its line-item ransack keys" do
    expect(Reporting::Reports::Packing::Customer).to receive(:new) do |_user, params|
      expect(params[:q]).to include(
        order_cycle_id_in: [translation_order_cycle.id.to_s],
        order_distributor_id_in: [translation_hub.id.to_s],
        order_completed_at_gt: completed_at_gt,
        order_completed_at_lt: completed_at_lt
      )
      expect(params[:q].keys).not_to include(:completed_at_gt, :completed_at_lt)
    end

    report_get(
      "packing",
      translation_params(
        report_subtype: "customer",
        distributor_id: translation_hub.id,
        q: { completed_at_gt:, completed_at_lt: }
      )
    )
  end

  [
    ["customer", Reporting::Reports::Packing::Customer],
    ["supplier", Reporting::Reports::Packing::Supplier],
    ["product", Reporting::Reports::Packing::Product]
  ].each do |subtype, report_class|
    it "constructs the #{subtype} packing subtype" do
      expect(report_class).to receive(:new).with(
        translation_hub_owner, hash_including(report_format: "json")
      ).and_call_original

      report_get("packing", translation_params(report_subtype: subtype))
    end
  end

  it "uses single-value eq predicates for xero invoices" do
    expect(Reporting::Reports::XeroInvoices::Summary).to receive(:new) do |_user, params|
      expect(params[:q]).to include(
        order_cycle_id_eq: translation_order_cycle.id.to_s,
        distributor_id_eq: translation_hub.id.to_s,
        completed_at_gt:,
        completed_at_lt:
      )
      expect(params[:q].keys).not_to include(:order_cycle_id_in, :distributor_id_in)
    end

    report_get(
      "xero_invoices",
      translation_params(
        report_subtype: "summary",
        distributor_id: translation_hub.id,
        q: { completed_at_gt:, completed_at_lt: }
      )
    )
  end

  it "uses an eq predicate for payments and sales tax distributor filters" do
    {
      "payments" => [
        Reporting::Reports::Payments::PaymentTotals,
        "payment_totals"
      ],
      "sales_tax" => [
        Reporting::Reports::SalesTax::SalesTaxTotalsByOrder,
        "sales_tax_totals_by_order"
      ]
    }.each do |report_type, (report_class, subtype)|
      expect(report_class).to receive(:new) do |_user, params|
        expect(params[:q]).to include(
          order_cycle_id_in: [translation_order_cycle.id.to_s],
          distributor_id_eq: translation_hub.id.to_s
        )
        expect(params[:q]).not_to include(:distributor_id_in)
      end

      report_get(
        report_type,
        translation_params(
          report_subtype: subtype,
          distributor_id: translation_hub.id
        )
      )
    end
  end

  it "keeps customers order-cycle and distributor IDs top-level" do
    expect(Reporting::Reports::Customers::Base).to receive(:new) do |_user, params|
      expect(params).to include(
        order_cycle_id: translation_order_cycle.id.to_s,
        distributor_id: translation_hub.id.to_s
      )
      expect(params[:q]).to include(completed_at_gt:, completed_at_lt:)
      expect(params[:q].keys).not_to include(:order_cycle_id, :distributor_id)
    end

    report_get(
      "customers",
      translation_params(
        distributor_id: translation_hub.id,
        q: { completed_at_gt:, completed_at_lt: }
      )
    )
  end

  it "keeps products-and-inventory IDs top-level" do
    expect(Reporting::Reports::ProductsAndInventory::AllProducts).to receive(:new) do |_user, params|
      expect(params).to include(
        order_cycle_id: translation_order_cycle.id.to_s,
        distributor_id: translation_hub.id.to_s
      )
    end

    report_get(
      "products_and_inventory",
      translation_params(
        report_subtype: "all_products",
        distributor_id: translation_hub.id
      )
    )
  end

  it "translates order-cycle-management distributor filtering through q" do
    expect(Reporting::Reports::OrderCycleManagement::PaymentMethods).to receive(:new) do |_user, params|
      expect(params).to include(order_cycle_id: translation_order_cycle.id.to_s)
      expect(params[:q]).to include(distributor_id_in: [translation_hub.id.to_s])
      expect(params.keys).not_to include(:distributor_id)
    end

    report_get(
      "order_cycle_management",
      translation_params(
        report_subtype: "payment_methods",
        distributor_id: translation_hub.id
      )
    )
  end

  it "uses plural array parameters for enterprise fee summary" do
    expect(Reporting::Reports::EnterpriseFeeSummary::FeeSummary).to receive(:new) do |_user, params|
      expect(params[:q]).to include(
        order_cycle_ids: [translation_order_cycle.id.to_s],
        distributor_ids: [translation_hub.id.to_s],
        completed_at_gt:,
        completed_at_lt:
      )
    end

    report_get(
      "enterprise_fee_summary",
      translation_params(
        report_subtype: "fee_summary",
        distributor_id: translation_hub.id,
        q: { completed_at_gt:, completed_at_lt: }
      )
    )
  end

  [
    ["enterprise_fees_with_tax_report_by_order",
     Reporting::Reports::EnterpriseFeeSummary::EnterpriseFeesWithTaxReportByOrder],
    ["enterprise_fees_with_tax_report_by_producer",
     Reporting::Reports::EnterpriseFeeSummary::EnterpriseFeesWithTaxReportByProducer]
  ].each do |subtype, report_class|
    it "uses _in arrays for #{subtype}" do
      expect(report_class).to receive(:new) do |_user, params|
        expect(params[:q]).to include(
          order_cycle_id_in: [translation_order_cycle.id.to_s],
          distributor_id_in: [translation_hub.id.to_s]
        )
      end

      report_get(
        "enterprise_fee_summary",
        translation_params(
          report_subtype: subtype,
          distributor_id: translation_hub.id
        )
      )
    end
  end

  it "selects the first configured packing subtype when none is supplied" do
    expect(Reporting::Reports::Packing::Customer).to receive(:new).and_call_original

    report_get("packing", translation_params)
  end

  it "rejects nested Ransack parameters outside the public whitelist" do
    expect(Reporting::Reports::Packing::Customer).not_to receive(:new)

    report_get(
      "packing",
      translation_params(
        report_subtype: "customer",
        q: { supplier_id_in: [] }
      )
    )

    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "registers the V1 reports route without a feature flag" do
    expect(Rails.application.routes.recognize_path("/api/v1/reports/packing")).to eq(
      controller: "api/v1/reports", action: "show", report_type: "packing"
    )
  end
end
