# frozen_string_literal: true

RSpec.describe "Shopfront menu" do
  describe "cart sidebar" do
    it "renders the AngularJS cart by default" do
      get shops_path

      expect(response.body).to include("CartDropdownCtrl")
      expect(response.body).not_to include('id="cart-sidebar"')
    end

    context "with the turbo cart enabled" do
      before do
        Flipper.enable(:turbo_cart)
        Flipper.enable(:product_grid_view)
      end

      it "renders the server-rendered cart" do
        get shops_path

        expect(response.body).to include('id="cart-sidebar"')
        expect(response.body).to include('data-controller="cart-sidebar"')
        expect(response.body).not_to include("CartDropdownCtrl")
      end
    end
  end
end
