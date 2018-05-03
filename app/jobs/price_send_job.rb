class PriceSendJob < ApplicationJob
  include SendgridMailer

  queue_as :low

  def perform(*args)
    send_price(*args)
  end
end
