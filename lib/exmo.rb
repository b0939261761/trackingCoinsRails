# frozen_string_literal: true

module Exmo

  EXMO_NAME = 'Exmo'
  EXMO_URL_PRICES = URI('https://api.exmo.com/v1/ticker/')

  def exmo
    response = Net::HTTP.get(EXMO_URL_PRICES)
    data = JSON.parse(response, symbolize_names: true)

    pairs = []
    prices = []

    data.each do |pair, pair_info|
      symbol = pair.to_s.gsub('_', '/')
      close_time = Time.at(pair_info[:updated].to_i).to_s(:db)
      price = pair_info[:last_trade]

      pairs << sql_pairs(symbol:symbol)
      prices << sql_prices(symbol:symbol, price: price, close_time: close_time)
    end

    insert_into_db(exchange_name: EXMO_NAME, pairs: pairs, prices: prices)
  end
end
