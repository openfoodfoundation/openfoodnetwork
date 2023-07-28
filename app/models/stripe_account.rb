# frozen_string_literal: true

class StripeAccount < ApplicationRecord
  self.belongs_to_required_by_default = false

  belongs_to :enterprise
  validates :stripe_user_id, :stripe_publishable_key, presence: true
  validates :enterprise_id, uniqueness: true

  def deauthorize_and_destroy
    accounts = StripeAccount.where(stripe_user_id: stripe_user_id)

    # Only deauthorize the user if it is not linked to multiple accounts
    return destroy if accounts.count > 1

    destroy && Stripe::OAuth.deauthorize(stripe_user_id: stripe_user_id)
  rescue Stripe::OAuth::OAuthError
    Bugsnag.notify(
      RuntimeError.new("StripeDeauthorizeFailure"),
      stripe_account: stripe_user_id,
      enterprise_id: enterprise_id
    )
    true
  end
end
