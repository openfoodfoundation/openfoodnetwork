# frozen_string_literal: true

require "spec_helper"

describe "admin/enterprises/form/_users.html.haml" do
  let(:enterprise) { build(:enterprise) }

  before do
    assign(:enterprise, enterprise)
    admin_user = build(:admin_user)
    allow(admin_user).to receive(:admin?) { true }
    allow(view).to receive_messages(
      f: enterprise_form,
      spree_current_user: admin_user,
    )
  end

  describe "notifications setting" do
    it "is visible when an enterprise is a distributor" do
      enterprise.sells = "any"

      render

      expect(rendered).to have_selector("select[name='receives_notifications']")
    end

    it "is not visible when an enterprise is a only a profile" do
      enterprise.sells = "none"

      render

      expect(rendered).not_to have_selector("select[name='receives_notifications']")
    end
  end

  private

  def enterprise_form
    form_for(enterprise) { |f| @enterprise_form = f }
    @enterprise_form
  end
end
