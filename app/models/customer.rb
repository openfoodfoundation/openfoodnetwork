class Customer < ActiveRecord::Base
  belongs_to :enterprise

  validates :code, presence: true, uniqueness: {scope: :enterprise_id}
  validates :email, presence: true
  validates :enterprise_id, presence: true
end
