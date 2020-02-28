FactoryBot.modify do
  factory :user do
    transient do
      enterprises []
    end

    confirmation_sent_at '1970-01-01 00:00:00'
    confirmed_at '1970-01-01 00:00:01'

    before(:create) do |user, evaluator|
      if evaluator.confirmation_sent_at
        if evaluator.confirmed_at
          user.skip_confirmation!
        else
          user.skip_confirmation_notification!
        end
      end
    end

    after(:create) do |user, proxy|
      user.spree_roles.clear # Remove admin role

      user.enterprises << proxy.enterprises
    end
  end

  factory :admin_user do
    confirmation_sent_at '1970-01-01 00:00:00'
    confirmed_at '1970-01-01 00:00:01'

    after(:create) do |user|
      user.spree_roles << Spree::Role.find_or_create_by!(name: 'admin')
    end
  end
end
