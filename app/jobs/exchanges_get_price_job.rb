class ExchangesGetPriceJob < ApplicationJob
  require 'net/http'

  include Binance
  include CheckNotifications
  include Yobit
  include Hitbtc
  include Livecoin
  include Exmo

  def perform
    binance
    hitbtc
    livecoin
    exmo

    yobit
    check_notifications
  end

  private

  def currencies
    @currencies ||= JSON.parse(Currency.select( :id, :symbol ).order( :symbol ).to_json, symbolize_names: true)
  end

  def compare_currencies(currency:)
    if currency
      all_compare = currencies.select { |o| currency.include?(o[:symbol]) }

      all_compare.each do |obj_first|
        first = obj_first[:symbol]

        all_compare.each do |second|
          second = second[:symbol]

          if first + second == currency
            return "#{first}/#{second}"
          end
        end
      end
    end

    return currency
  end
end
