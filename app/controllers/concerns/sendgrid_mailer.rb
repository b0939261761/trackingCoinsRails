# frozen_string_literal: true

# Send email
module SendgridMailer
  require 'net/http'

  MAIL_API_URL = URI('https://api.sendgrid.com/v3/mail/send')

  MAIL_HEADER = {
    authorization: "Bearer #{ENV['SENDGRID_API_KEY']}",
    'Content-Type': 'application/json'
  }.freeze

  FROM_NAME = 'Rails Coins'

  def format_number(value)
    ActiveSupport::NumberHelper.number_to_delimited(value, delimiter: ' ', separator: '.')
  end

  def send_email(email_to:, template_id:, substitutions:)
    body = {
      personalizations: [{
        to: [{ email: email_to }],
        substitutions: substitutions
      }],
      from: {
        email: ENV['EMAIL_FROM'],
        name: FROM_NAME
      },
      template_id: template_id
    }.to_json

    body
    response = Net::HTTP.post(
      MAIL_API_URL,
      body,
      MAIL_HEADER
    )

    if response.code == '202'
      false
    else
      response
    end
  end

  def send_confirmation(user_id:, email:, lang:)
    substitutions = {
      '<%link%>': "#{ENV['SITE_URL']}/confirm_registration?token=" \
                  "#{registration_token(user_id: user_id)}"
    }

    templates = {
      en: ENV['TEMPLATE_CONFIRM_EN'],
      ru: ENV['TEMPLATE_CONFIRM_RU']
    }

    send_email(
      email_to: email,
      template_id: templates[lang],
      substitutions: substitutions
    )
  end

  def send_recovery(user_id:, email:, lang:)
    substitutions = {
      '<%link%>': "#{ENV['SITE_URL']}/confirm_recovery?token=" \
                  "#{recovery_token(user_id: user_id)}"
    }

    templates = {
      en: ENV['TEMPLATE_RECOVERY_EN'],
      ru: ENV['TEMPLATE_RECOVERY_RU']
    }

    send_email(
      email_to: email,
      template_id: templates[lang],
      substitutions: substitutions
    )
  end

  def send_price(email:, lang:, prices:)
    lang = lang.to_sym
    direction_text = {
      en: { less: 'Low', above: 'High' },
      ru: { less: 'Меньше', above: 'Больше' }
    }

    dirrections = {
      less: { text: direction_text[lang][:less], icon: '&darr;', icon_color: 'green' },
      above: { text: direction_text[lang][:above], icon: '&uarr;', icon_color: 'blue' }
    }

    rows = ''
    prices.each do |o|
      direction = dirrections[ o[:direction].to_sym ]
      current_price = o[:current_price].to_f
      price = o[:price].to_f
      diff = current_price - price
      percent = (current_price / price * 100).round(3)

      rows += '<tr style="background-color: #fff; height: 50px; color: #000; font-size:14px; color: #333333; text-align: right;background-color: #e2e2e2">' \
        "<td style=\"border-width: 0; border-bottom: 1px dotted #777; border-left: 1px dotted #777; text-align: center;\">#{o[:currency]}</td>" \
        "<td style=\"border-width: 0; border-bottom: 1px dotted #777; text-align: left;\">#{o[:exchange]}</td>" \
        '<td style="border-width: 0; border-bottom: 1px dotted #777; text-align: center;">' \
          "<span style=\"color: #{direction[:icon_color]};\">#{direction[:icon]}</span> #{direction[:text]}" \
        '</td>' \
        "<td style=\"border-width: 0; border-bottom: 1px dotted #777;\">#{format_number(price)}</td>" \
        "<td style=\"border-width: 0; border-bottom: 1px dotted #777;\">#{format_number(current_price)}</td>" \
        "<td style=\"border-width: 0; border-bottom: 1px dotted #777;\">#{format_number(diff)}</td>" \
        "<td style=\"border-bottom: 1px dotted #777; border-rigth: 1px dotted #777;\">#{format_number(percent)}</td>" \
      '</tr>'
    end

    templates = {
      en: ENV['TEMPLATE_PRICE_EN'],
      ru: ENV['TEMPLATE_PRICE_RU']
    }

    send_email(
      email_to: email,
      template_id: templates[lang],
      substitutions: { '<%rows%>': rows }
    )
  end
end
