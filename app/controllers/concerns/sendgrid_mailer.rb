# frozen_string_literal: true

# Send email
module SendgridMailer
  require 'net/http'

  MAIL_API_URL = URI(ENV['SENDGRID_API_URL'])
  WEB_URL = ENV['WEB_URL']

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
      '<%link%>': "#{WEB_URL}/confirm_registration?token=" \
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
      '<%link%>': "#{WEB_URL}/confirm_recovery?token=" \
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

    dirrections = {
      less: { icon: '&darr;', icon_color: 'red' },
      above: { icon: '&uarr;', icon_color: 'green' }
    }

    rows = ''
    prices.each do |o|
      direction = dirrections[ o[:direction].to_sym ]
      last = o == prices[-1]
      style_border = 'border-width: 0; border-bottom: 1px solid #caa9a9;'

      rows += text = <<~TEXT
        <tr style="background-color: #ffffff; height: 50px; color: #000000; font-size:14px; color: #333333; text-align: center;">
          <td style="#{last ? 'border-radius: 0 0 0 8px;' : ''}#{style_border} border-left: 1px solid #caa9a9;">
            #{o[:currency]}</td>
          <td style="#{style_border}">#{o[:exchange]}</td>
          <td style="#{style_border}">
            <span style=\"color: #{direction[:icon_color]};\">#{direction[:icon]}</span>#{I18n.t(o[:direction])}
          </td>
          <td style="#{style_border}\">#{o[:price]}</td>
          <td style="#{style_border}\">#{o[:current_price]}</td>
          <td style="#{style_border}\">#{o[:diff]}</td>
          <td style="#{last ? 'border-radius: 0 0 8px 0;' : ''}#{style_border} border-right: 1px solid #caa9a9;">
            #{o[:percent]}%</td>
        </tr>
      TEXT
    end

    templates = {
      en: ENV['TEMPLATE_PRICE_EN'],
      ru: ENV['TEMPLATE_PRICE_RU']
    }

    send_email(
      email_to: email,
      template_id: templates[lang],
      substitutions: {
        '<%rows%>': rows,
        '<%link%>': WEB_URL
      }
    )
  end
end
