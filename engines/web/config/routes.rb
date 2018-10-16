Web::Engine.routes.draw do
  namespace :api do
    scope '/cookies' do
      resource :consent, only: [:show, :create, :destroy], controller: "cookies_consent"
    end
  end

  get "/angular-templates/:id", to: "angular_templates#show", constraints: { name: %r{[\/\w\.]+} }
end
