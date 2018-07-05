# frozen_string_literal: true

class MonitoringAccount < ApplicationRecord
  belongs_to :user
  has_many :farms
end
