# frozen_string_literal: true

module Cex

  CEX_NAME = 'CEX'
  CEX_URL_PAIRS = URI('https://cex.io/api/currency_limits')
  CEX_URL_PRICES = 'https://cex.io/api/tickers/'

  def cex
    response_pairs = Net::HTTP.get(CEX_URL_PAIRS)
    data_pairs = JSON.parse(response_pairs, symbolize_names: true)

    pairs = []
    prices = []

    data_pairs[:data][:pairs].uniq{ |o| o[:symbol2] }.each do |pair|
      url_prices = URI("#{CEX_URL_PRICES}/#{pair[:symbol2]}")
      p url_prices
      response_prices = Net::HTTP.get(url_prices)
      data_prices = JSON.parse(response_prices, symbolize_names: true)

      data_prices[:data].each do |pair_info|
        symbol = pair_info[:pair].to_s.upcase.sub(':', '/')
        close_time = Time.at(pair_info[:timestamp].to_i).to_s(:db)
        price = pair_info[:last]

        pairs << sql_pairs(symbol:symbol)
        prices << sql_prices(symbol:symbol, price: price, close_time: close_time)
      end
    end

    insert_into_db(exchange_name: CEX_NAME, pairs: pairs, prices: prices)
  end
end
