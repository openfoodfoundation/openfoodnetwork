# frozen_string_literal: true

DfcProvider::Engine.routes.draw do
  resources :addresses, only: [:show]
  resources :enterprises, only: [:show] do
    resources :catalog_items, only: [:index, :show, :update]
    resources :supplied_products, only: [:create, :show, :update]
  end
  resources :enterprise_groups, only: [:index, :show]
  resources :persons, only: [:show]
end
