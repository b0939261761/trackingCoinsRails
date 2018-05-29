# frozen_string_literal: true

module Bittrex

  BITTREX_NAME = 'Bittrex'
  BITTREX_URL_PRICES = URI('https://bittrex.com/api/v1.1/public/getmarketsummaries')

  def bittrex
    response = Net::HTTP.get(BITTREX_URL_PRICES)
    data = JSON.parse(response, symbolize_names: true)

    pairs = []
    prices = []

    data[:result].each do |pair_info|
      symbol = pair_info[:MarketName].to_s.gsub('-', '/')
      close_time = pair_info[:TimeStamp]
      price = pair_info[:Last]


      pairs << sql_pairs(symbol:symbol)
      prices << sql_prices(symbol:symbol, price: price, close_time: close_time)
    end

    insert_into_db(exchange_name: BITTREX_NAME, pairs: pairs, prices: prices)
  end
end
