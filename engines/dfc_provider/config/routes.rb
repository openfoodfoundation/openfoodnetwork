# frozen_string_literal: true

DfcProvider::Engine.routes.draw do
  resources :enterprises, only: [:show] do
    resources :catalog_items, only: [:index, :show]
    resources :supplied_products, only: [:show, :update]
  end
  resources :persons, only: [:show]
end
