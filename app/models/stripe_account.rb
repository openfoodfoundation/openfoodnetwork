class StripeAccount < ActiveRecord::Base
  belongs_to :enterprise
  validates_presence_of :stripe_user_id, :stripe_publishable_key
  validates_uniqueness_of :enterprise_id

  def deauthorize_and_destroy
    accounts = StripeAccount.where(stripe_user_id: stripe_user_id)

    # Only deauthorize the user if it is not linked to multiple accounts
    if accounts.count > 1 || Stripe::OAuth.deauthorize(stripe_user_id)
      destroy
    else
      false
    end
  end
end
