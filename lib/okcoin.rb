# frozen_string_literal: true

module Okcoin

  OKCOIN_NAME = 'OKCoin'
  OKCOIN_URL_PRICE = 'https://www.okcoin.com/api/v1/ticker.do?symbol='

  def okcoin
    data_pairs = %w(btc_usd ltc_usd eth_usd etc_usd bch_usd)

    pairs = []
    prices = []

    data_pairs.each do |pair|
      url_price = URI("#{OKCOIN_URL_PRICE}#{pair}")
      response_price = Net::HTTP.get(url_price)
      pair_info = JSON.parse(response_price, symbolize_names: true)

      symbol = pair.upcase.sub('_', '/')
      close_time = Time.at(pair_info[:date].to_i).to_s(:db)
      price = pair_info[:ticker][:last]

      pairs << sql_pairs(symbol:symbol)
      prices << sql_prices(symbol:symbol, price: price, close_time: close_time)
    end

    insert_into_db(exchange_name: OKCOIN_NAME, pairs: pairs, prices: prices)
  end
end
