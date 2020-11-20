Openfoodnetwork::Application.routes.append do
  scope '/api/cookies' do
    resource :consent, only: [:show, :create, :destroy], controller: "web/api/cookies_consent"
  end

  get "/angular-templates/:id", to: "web/angular_templates#show", constraints: { name: %r{[\/\w\.]+} }
end
