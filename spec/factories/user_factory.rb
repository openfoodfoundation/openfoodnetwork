# frozen_string_literal: true

FactoryBot.define do
  sequence :user_authentication_token do |n|
    "xxxx#{Time.now.to_i}#{rand(1000)}#{n}xxxxxxxxxxxxx"
  end

  factory :user, class: Spree::User do
    email { generate(:random_email) }
    login { email }
    password { 'secret' }
    password_confirmation { password }
    if Spree::User.attribute_method? :authentication_token
      authentication_token {
        generate(:user_authentication_token)
      }
    end

    confirmation_sent_at { '1970-01-01 00:00:00' }
    confirmed_at { '1970-01-01 00:00:01' }
    terms_of_service_accepted_at { 1.hour.ago }

    before(:create) do |user, evaluator|
      if evaluator.confirmation_sent_at
        if evaluator.confirmed_at
          user.skip_confirmation!
        else
          user.skip_confirmation_notification!
        end
      end
    end

    factory :admin_user do
      spree_roles { [Spree::Role.find_or_create_by!(name: 'admin')] }
    end

    factory :oidc_user do
      after(:create) do |user|
        OidcAccount.create!(user:, provider: "openid_connect", uid: user.email)
      end
    end
  end
end
