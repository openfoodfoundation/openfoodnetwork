Web::Engine.routes.draw do
  namespace :web do
    namespace :api do
      scope '/cookies' do
        resource :consent, only: [:show, :create, :destroy], controller: "cookies_consent"
      end
    end
  end
end
