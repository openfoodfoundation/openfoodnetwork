require "spec_helper"

describe "spree/admin/payment_methods/index.html.haml" do
  before do
    controller.singleton_class.class_eval do
      helper_method :new_object_url, :edit_object_url, :object_url

      def new_object_url() "" end

      def edit_object_url(object, options = {}) "" end

      def object_url(object = nil, options = {}) "" end
    end

    assign(:payment_methods, [
      create(:payment_method),
      create(:payment_method)
    ])
  end

  describe "payment methods index page" do
    it "shows only the providers of the existing payment methods" do
      render

      expect(rendered).to have_content "Cash/EFT/etc. (payments for which automatic validation is not required)", count: 2
    end
  end
end
