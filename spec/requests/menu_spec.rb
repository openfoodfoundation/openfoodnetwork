# frozen_string_literal: true

RSpec.describe "Shopfront menu" do
  describe "cart sidebar" do
    it "renders the AngularJS cart by default" do
      get shops_path

      expect(response.body).to include("CartDropdownCtrl")
      expect(response.body).not_to include('id="cart-sidebar"')
    end

    context "with the product grid view enabled", feature: :product_grid_view do
      it "renders the server-rendered cart" do
        get shops_path

        expect(response.body).to include('id="cart-sidebar"')
        expect(response.body).to include('data-controller="cart-sidebar"')
        expect(response.body).not_to include("CartDropdownCtrl")
      end
    end
  end
end
