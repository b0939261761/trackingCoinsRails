# frozen_string_literal: true

module Livecoin

  LIVECOIN_NAME = 'Livecoin'
  LIVECOIN_URL_PRICES = URI('https://api.livecoin.net/exchange/ticker')

  def livecoin
    response = Net::HTTP.get(LIVECOIN_URL_PRICES)
    data = JSON.parse(response, symbolize_names: true)

    pairs = []
    prices = []
    close_time = Time.new

    data.each do |pair_info|
      symbol = pair_info[:symbol]
      price = pair_info[:last]

      pairs << sql_pairs(symbol:symbol)
      prices << sql_prices(symbol:symbol, price: price, close_time: close_time)
    end

    insert_into_db(exchange_name: LIVECOIN_NAME, pairs: pairs, prices: prices)
  end
end
