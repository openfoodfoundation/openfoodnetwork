# frozen_string_literal: true

DfcProvider::Engine.routes.draw do
  resources :addresses, only: [:show]
  resources :enterprises, only: [:show] do
    resources :catalog_items, only: [:index, :show, :update]
    resources :offers, only: [:show]
    resources :supplied_products, only: [:create, :show, :update]
    resources :social_medias, only: [:show]
  end
  resources :enterprise_groups, only: [:index, :show] do
    resources :affiliated_by, only: [:create, :destroy], module: 'enterprise_groups'
  end
  resources :persons, only: [:show]
end
