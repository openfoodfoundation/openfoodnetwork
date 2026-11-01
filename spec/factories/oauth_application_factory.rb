# frozen_string_literal: true

FactoryBot.define do
  factory :oauth_application, class: Doorkeeper::Application do
    sequence(:name) { |n| "External app #{n}" }
    redirect_uri { "https://app.example.com/callback" }
  end
end
