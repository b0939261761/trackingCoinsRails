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
end
