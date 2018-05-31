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

eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyIjoxuCp2pgGN87Xs
eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyIjoxMywidHlwZSI6InJlZnJlc2giLCJleHAiOjE1Mjc4Mzc1Nzd9.ogY76YMm2lMhqui_MAf34qbrcwJB7ULuCp2pgGN87Xs
