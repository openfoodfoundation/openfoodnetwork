# frozen_string_literal: true

DfcProvider::Engine.routes.draw do
  namespace :api do
    scope :dfc_provider, as: :dfc_provider, path: '/dfc_provider' do
      resources :enterprises, only: :none do
        resources :products, only: %i[index]
      end
    end
  end
end
