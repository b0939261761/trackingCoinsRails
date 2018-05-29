# frozen_string_literal: true

# Access to site
module Binance

  BINANCE_NAME = 'Binance'
  BINANCE_URL_PRICES = URI('https://api.binance.com/api/v1/ticker/24hr')

  def binance
    response = Net::HTTP.get(BINANCE_URL_PRICES)
    data = JSON.parse(response, symbolize_names: true)

    pairs = []
    prices = []

    data.each do |pair_info|
      symbol = compare_currencies(currency: pair_info[:symbol])
      close_time = Time.at(pair_info[:closeTime].to_i/1000).to_s(:db)
      price = pair_info[:lastPrice]

      pairs << sql_pairs(symbol:symbol)
      prices << sql_prices(symbol:symbol, price: price, close_time: close_time)
    end

    insert_into_db(exchange_name: BINANCE_NAME, pairs: pairs, prices: prices)
  end
end
