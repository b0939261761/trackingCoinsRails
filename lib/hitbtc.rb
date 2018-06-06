# frozen_string_literal: true

module Hitbtc

  HITBTC_NAME = 'HitBTC'
  HITBTC_URL_PAIRS = URI('https://api.hitbtc.com/api/2/public/symbol')
  HITBTC_URL_PRICES = URI('https://api.hitbtc.com/api/2/public/ticker')

  def hitbtc
    response_pairs = Net::HTTP.get(HITBTC_URL_PAIRS)
    data_pairs = JSON.parse(response_pairs, symbolize_names: true)

    response_prices = Net::HTTP.get(HITBTC_URL_PRICES)
    data_prices = JSON.parse(response_prices, symbolize_names: true)

    pairs = []
    prices = []
    
    data_prices.each do |pair_info|
      pair = data_pairs.find { |o| pair_info[:symbol] == o[:id] }

      symbol = pair ? "#{pair[:baseCurrency]}/#{pair[:quoteCurrency]}" : pair_info[:symbol]

      close_time = pair_info[:timestamp]
      price = pair_info[:last] || 0

      pairs << sql_pairs(symbol:symbol)
      prices << sql_prices(symbol:symbol, price: price, close_time: close_time)
    end

    insert_into_db(exchange_name: HITBTC_NAME, pairs: pairs, prices: prices)
  end
end
