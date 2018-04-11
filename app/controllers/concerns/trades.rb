# frozen_string_literal: true

# Access to site
module Trades
  def binance
    # url = URI('https://api.binance.com/api/v1/ticker/24hr')
    # response = Net::HTTP.get(url)

    # File.open('binare.txt', 'w') { |f| f.write(response) }
    response = File.open('binare.txt')

  end
end
