# frozen_string_literal: true

module Nanopool
  NANOPOOL_URL = 'https://api.nanopool.org/v1/eth/reportedhashrates/'

  def nanopool
    users = User.select(:id, :telegram_chat_id, :nanopool_address)
      .where(telegram_enabled: true, telegram_activated: true)
      .where.not(nanopool_address: '')

    users.each_slice(25) do |users_piece|
      sleep 1

      users_piece.each do |user|
        workers = nanopool_respond_info(user_id: user[:id], address: user[:nanopool_address])
        if workers[:all].any?
          nanopool_telegram_send(chat_id: user[:telegram_chat_id], workers: workers[:all])
        end

        if workers[:fail].any?
          nanopool_telegram_send_fail(chat_id: user[:telegram_chat_id], workers_fail: workers[:fail])
        end
      end
    end
  end

  def nanopool_respond_info(user_id:, address:)
    response = Net::HTTP.get(URI("#{NANOPOOL_URL}#{address}"))
    data = JSON.parse(response, symbolize_names: true)
    workers_all = []
    workers_fail = []

    if data[:status]
      data[:data].each do |o|
        hashrate = o[:hashrate].to_f.round(3)
        worker = o[:worker]
        farm = Farm.find_by(user_id: user_id, name: worker)
        if hashrate.nonzero?
          if farm
            amount = farm.amount
            sum_hashrate = farm.sum_hashrate

            new_amount = amount + 1
            new_sum_hashrate = sum_hashrate + hashrate
            diff_percent =(100-(new_sum_hashrate / new_amount) / (sum_hashrate / amount)*100).round(1)

            worker = { worker: worker, hashrate: hashrate, diff_percent: diff_percent }

            if amount > 5 && diff_percent >= 7.5
              workers_fail << worker
            end

            workers_all << worker
            farm.update(sum_hashrate: new_sum_hashrate, amount: new_amount)
          else
            Farm.create(user_id: user_id, name: worker, sum_hashrate: hashrate, amount: 1)
          end
        else
          workers_fail << worker
        end
      end
    end

    { all: workers_all, fail: workers_fail }
  end

  def nanopool_telegram_send(chat_id:, workers:)
    bot = Telegram::Bot::Client.new(ENV['TELEGRAM_BOT_TOKEN'])
    text = workers.map{ |o| "*#{o[:worker]}*: `#{o[:hashrate]}` #{o[:diff_percent]}%"}.join('\n')
    bot.send_message chat_id: chat_id, text: text, parse_mode: 'Markdown'
  end

  def nanopool_telegram_send_fail(chat_id:, workers_fail:)
    bot = Telegram::Bot::Client.new(ENV['TELEGRAM_BOT_TOKEN'])
    text = workers_fail.map{ |o| "*#{o[:worker]}*: `#{o[:hashrate]}` #{o[:diff_percent]}%"}.join('\n')
    photo = 'https://i.imgur.com/Dr5Hwyj.png'
    bot.public_send :send_photo, chat_id: chat_id, photo: photo, caption: text, parse_mode: 'Markdown'
  end
end
