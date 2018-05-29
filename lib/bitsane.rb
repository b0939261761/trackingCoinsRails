# frozen_string_literal: true

module Bitsane

  BITSANE_NAME = 'Bitsane'
  BITSANE_URL_PRICES = URI('https://bitsane.com/api/public/ticker')

  def bitsane
    response = Net::HTTP.get(BITSANE_URL_PRICES)
    data = JSON.parse(response, symbolize_names: true)

    pairs = []
    prices = []
    close_time = Time.new

    data.each do |pair, pair_info|
      symbol = pair.to_s.gsub('_', '/')
      price = pair_info[:last]

      pairs << sql_pairs(symbol:symbol)
      prices << sql_prices(symbol:symbol, price: price, close_time: close_time)
    end

    insert_into_db(exchange_name: BITSANE_NAME, pairs: pairs, prices: prices)
  end
end
