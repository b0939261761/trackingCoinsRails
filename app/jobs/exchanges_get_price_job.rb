class ExchangesGetPriceJob < ApplicationJob
  require 'net/http'

  include AdditionalForExchanges
  include CheckNotifications

  include Binance
  include Yobit
  include Hitbtc
  include Livecoin
  include Exmo
  include Bittrex
  include Bitstamp
  include Cex
  include Bitsane
  include Okcoin

  def perform
    binance
    hitbtc
    livecoin
    exmo
    bittrex
    bitstamp
    cex
    bitsane
    okcoin
    yobit

    check_notifications
  end
end
