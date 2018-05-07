class PriceSendJob < ApplicationJob
  include SendgridMailer

  queue_as :notifications

  def perform(*args)
    send_price(*args)
  end
end
