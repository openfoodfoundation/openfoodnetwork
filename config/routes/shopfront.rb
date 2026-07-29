# frozen_string_literal: true

Openfoodnetwork::Application.routes.draw do
  # Enterprise shopfront routes live at the root of the URL space, e.g.
  # /my-farm-shop/products/1. They are drawn last so that they never shadow
  # admin, API or Spree routes. See config/application.rb for the draw order.
  resources :enterprises, only: [], path: "", param: :permalink do
    # This is the more Railsy way to express the `enterprise_shop` route:
    #   /:permalink/shop
    #
    # We may want to switch to this but there are some outstanding tasks:
    # - Change params[:id] to params[:permalink] in enterprises#shop.
    # - Change enterprise_shop_path → shop_enterprise_path
    #get :shop, on: :member

    resources :products, only: [:show]
  end
end
