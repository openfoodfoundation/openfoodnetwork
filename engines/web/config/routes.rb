# frozen_string_literal: true

Openfoodnetwork::Application.routes.append do
  scope '/api/v0/cookies' do
    resource :consent, only: [:show, :create, :destroy], controller: "web/api/v0/cookies_consent"
  end

  get "/angular-templates/:id", to: "web/angular_templates#show",
                                constraints: { name: %r{[/\w.]+} }
end
