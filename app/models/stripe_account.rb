class StripeAccount < ActiveRecord::Base
  belongs_to :enterprise
  valdates_presence_of :stripe_user_id, :stripe_publishable_key
  validates_uniqueness_of :stripe_user_id
end
