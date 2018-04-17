class Notification < ApplicationRecord
  belongs_to :exchange
  belongs_to :pair

  validates_uniqueness_of :user_id, scope: %i(pair_id direction price)
end
