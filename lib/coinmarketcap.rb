# frozen_string_literal: true

#
module Coinmarketcap
  def coinmarketcap
    url = URI('https://api.coinmarketcap.com/v2/listings/')
    response = Net::HTTP.get(url)

    data = JSON.parse(response, symbolize_names: true)

    currencies = data[:data].map do |o|
      "( '#{o[:symbol]}', '#{o[:name].gsub("'", '')}', '#{o[:website_slug]}' )"
    end
    result = []
    data[:data].sort_by{ |o| o[:symbol ]}.group_by{ |o| o[:symbol] }.each { |k,v|
    result<< k if v.size > 1
    }

    result
    # sql = <<-SQL
    #   -- Добавляем валюты
    #   INSERT INTO currencies (
    #     symbol,
    #     name,
    #     slug
    #   )
    #     VALUES
    #       #{currencies.join(',')}
    #     ON CONFLICT ( symbol )
    #       DO UPDATE SET
    #         name = EXCLUDED.name,
    #         slug = EXCLUDED.slug
    # SQL

    # JSON.parse(ActiveRecord::Base.connection.execute(sql).to_json, symbolize_names: true)
  end
end
