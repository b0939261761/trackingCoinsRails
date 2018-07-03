# frozen_string_literal: true

module Bitstamp

  BITSTAMP_NAME = 'Bitstamp'
  BITSTAMP_URL_PAIRS = URI('https://www.bitstamp.net/api/v2/trading-pairs-info/')
  BITSTAMP_URL_PRICE = 'https://www.bitstamp.net/api/v2/ticker/'

  def bitstamp
    response_pairs = Net::HTTP.get(BITSTAMP_URL_PAIRS)
    data_pairs = JSON.parse(response_pairs, symbolize_names: true)

    pairs = []
    prices = []

    data_pairs.each do |pair|
      url_price = URI("#{BITSTAMP_URL_PRICE}#{pair[:url_symbol]}")
      response_price = Net::HTTP.get(url_price)
      pair_info = JSON.parse(response_price, symbolize_names: true)

      symbol = pair[:name].to_s.upcase.sub('_', '/')
      close_time = Time.at(pair_info[:timestamp].to_i).to_s(:db)
      price = pair_info[:last]

      pairs << sql_pairs(symbol:symbol)
      prices << sql_prices(symbol:symbol, price: price, close_time: close_time)
    end

    insert_into_db(exchange_name: BITSTAMP_NAME, pairs: pairs, prices: prices)
  end
end
