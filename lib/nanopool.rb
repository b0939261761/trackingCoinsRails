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
        begin
          workers = nanopool_respond_info(user_id: user[:id], address: user[:nanopool_address])
        rescue Exception => e
          logger.error("ERROR NANOPOOL USER_ID #{user[:id]}: #{e}")
        end

        chat_id = user[:telegram_chat_id]

        workers.each do |k, v|
          nanopool_telegram_send(type: k, chat_id: chat_id, workers: v) if v.any?
        end
      end
    end
  end

  def nanopool_respond_info(user_id:, address:)
    response = Net::HTTP.get(URI("#{NANOPOOL_URL}#{address}"))
    data = JSON.parse(response, symbolize_names: true)
    workers_fail = []
    workers_success = []
    workers_above = []
    workers_less = []

    if data[:status]
      data[:data].each do |o|
        hashrate = o[:hashrate].to_f.round(2)

        worker_name = o[:worker]
        farm = Farm.find_by(user_id: user_id, name: worker_name)
        worker = { worker: worker_name, hashrate: hashrate, diff_percent: 0 }

        if farm
          amount = farm.amount
          new_amount = amount
          sum_hashrate = farm.sum_hashrate
          new_sum_hashrate = sum_hashrate
          activated = farm.activated
          counter_zero = farm.counter_zero

          if hashrate.nonzero?
            counter_zero = 0
            new_amount += 1
            new_sum_hashrate += hashrate
            diff_percent =(hashrate / sum_hashrate * amount * 100 - 100).round(1)
            worker[:diff_percent] = diff_percent
            if amount > 5 && activated
              workers_less << worker if diff_percent <= -7.5
              workers_above << worker if diff_percent >= 7.5
            end

            workers_success << worker if farm.last_hashrate.zero? && activated
          else
            counter_zero += 1
            # Первый 5 раз через 5 минут, потом следующие 5 раз через 60 минут, и стоп
            workers_fail << worker if activated && counter_zero < 306 && (counter_zero < 6 || ((counter_zero - 5) % 60).zero?)
          end

          farm.update(sum_hashrate: new_sum_hashrate, amount: new_amount, last_hashrate: hashrate, counter_zero: counter_zero)
        else
          Farm.create(user_id: user_id, name: worker_name, sum_hashrate: hashrate, amount: 1)
        end
      end
    end

    { success: workers_success, above: workers_above, less: workers_less, fail: workers_fail }
  end

  def bot
    @bot ||= Telegram::Bot::Client.new(ENV['TELEGRAM_BOT_TOKEN'])
  end

  def telegram_send_photo(chat_id:, photo:, caption:)
    bot.public_send :send_photo, chat_id: chat_id, photo: photo, caption: caption, parse_mode: 'Markdown'
  end

  def nanopool_telegram_send(type:, chat_id:, workers:)
    text = workers.map do|o|
      case type
      when :success
        "Rigs ONLINE *#{o[:worker]}*\nHashrate: `#{o[:hashrate]} Mh/s`"
      when :fail
        "Rigs OFFLINE *#{o[:worker]}*"
      when :less
        "Worker: *#{o[:worker]}*\nHashrate: `#{o[:hashrate]} Mh/s` #{o[:diff_percent]}%"
      when :above
        "Worker: *#{o[:worker]}*\nHashrate: `#{o[:hashrate]} Mh/s` #{o[:diff_percent]}%"
      else
        ''
      end
    end
    .join("\n")

    photo_name = { fail: 'Djy8ahL', less: 'Djy8ahL', above: 'oE2blbW', success: 'EB9A536' }
    photo = "https://imgur.com/#{photo_name[type]}.png"
    telegram_send_photo chat_id: chat_id, photo: photo, caption: text
  end
end
