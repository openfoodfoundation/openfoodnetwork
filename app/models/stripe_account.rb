class StripeAccount < ActiveRecord::Base
  belongs_to :enterprise
  validates :stripe_user_id, :stripe_publishable_key, presence: true
  validates :enterprise_id, uniqueness: true

  def deauthorize_and_destroy
    accounts = StripeAccount.where(stripe_user_id: stripe_user_id)

    # Only deauthorize the user if it is not linked to multiple accounts
    if accounts.count > 1 || Stripe::OAuth.deauthorize(stripe_user_id: stripe_user_id)
      destroy
    else
      false
    end
  rescue Stripe::OAuth::OAuthError
    false
  end
end
