# frozen_string_literal: true

DfcProvider::Engine.routes.draw do
  constraints DfcProvider::ActivationConstraint.new do
    namespace :admin do
      resource :dfc_provider_settings, only: %i[show]
    end

    namespace :api do
      namespace :v0 do
        scope :dfc_provider, as: :dfc_provider, path: '/dfc_provider' do
          # Just used for the JSON-LD context base url generation
          get '/', to: redirect('/'), as: :base

          resources :enterprises, only: [:show] do
            resources :catalog_items, only: [:index, :show]
            resources :supplied_products, only: [:show]
          end
          resources :persons, only: [:show]
        end
      end
    end
  end
end
