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

    p body
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
    rows = ''
    prices.each do |o|
      rows += '<tr style="border: 1px solid #B9B9B9; background-color: #E0E0E0; height: 50px; color: #000; padding: 10px;">' \
        "<td>#{o[:currency]}</td>" \
        "<td>#{o[:exchange]}</td>" \
        '<td>??????</td>' \
        "<td>#{o[:price]}</td>" \
        "<td>#{o[:direction]}</td>"\
      '</tr>'
    end

    templates = {
      en: ENV['TEMPLATE_PRICE_EN'],
      ru: ENV['TEMPLATE_PRICE_RU']
    }

    send_email(
      email_to: email,
      template_id: templates[lang.to_sym],
      substitutions: { '<%rows%>': rows }
    )
  end
end
