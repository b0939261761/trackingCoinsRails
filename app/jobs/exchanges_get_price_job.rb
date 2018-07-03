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
    exchanges = %w(binance hitbtc livecoin exmo yobit
                   bittrex bitstamp cex bitsane okcoin)
    exchanges.each do |exchange|
      begin
        # public_send(exchange)
      rescue Exception => e
        logger.error("ERROR GET EXCHANGES #{exchange}: #{e}")
      end
    end

    check_notifications
  end
end
