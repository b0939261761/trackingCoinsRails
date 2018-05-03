class ExchangesGetPriceJob < ApplicationJob
  require 'net/http'

  include Binance
  include CheckNotifications

  def perform
    binance
    check_notifications
  end
end
