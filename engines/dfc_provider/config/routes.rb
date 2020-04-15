# frozen_string_literal: true

DfcProvider::Engine.routes.draw do
  namespace :api do
    namespace :dfc_provider do
      resources :enterprises, only: :none do
        resources :products, only: %i[index]
      end
    end
  end
end
