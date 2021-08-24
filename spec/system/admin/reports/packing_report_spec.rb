# frozen_string_literal: true

require "system_helper"

feature "Packing Reports", js: true do
  include AuthenticationHelper
  include WebHelper

  let(:distributor) { create(:distributor_enterprise) }
  let(:oc) { create(:simple_order_cycle) }
  let(:order) { create(:order, completed_at: 1.day.ago, order_cycle: oc, distributor: distributor) }
  let(:li1) { build(:line_item_with_shipment) }
  let(:li2) { build(:line_item_with_shipment) }

  before do
    order.line_items << li1
    order.line_items << li2
    login_as_admin
  end

  describe "viewing a report" do
    context "when an associated variant has been soft-deleted" do
      it "shows line items" do
        li1.variant.delete

        visit spree.admin_reports_path

        click_on I18n.t("admin.reports.packing.name")
        select oc.name, from: "q_order_cycle_id_in"

        find('#q_completed_at_gt').click
        select_date(Time.zone.today - 1.day)

        find('#q_completed_at_lt').click
        select_date(Time.zone.today)

        find("button[type='submit']").click

        expect(page).to have_content li1.product.name
        expect(page).to have_content li2.product.name
      end
    end
  end
end
