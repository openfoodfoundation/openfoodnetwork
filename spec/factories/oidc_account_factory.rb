# frozen_string_literal: true

FactoryBot.define do
  factory :oidc_account, class: OidcAccount do
    provider { "openid_connect" }
    uid { user&.email || generate(:random_email) }

    # This is a live test account authenticated via Les Communes.
    # See .env.test for tips on connecting the account for recording VCR cassettes.
    factory :testdfc_account do
      uid { "testdfc@protonmail.com" }
      refresh_token { ENV.fetch("OPENID_REFRESH_TOKEN") }
      updated_at { 1.day.ago }
    end
  end
end
