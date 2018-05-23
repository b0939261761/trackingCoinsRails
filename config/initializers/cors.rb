# frozen_string_literal: true

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(/localhost:\d*/,
            '192.168.5.141',
            'cryptonot.io')

    resource '*',
             headers: :any,
             expose: ['Access-Token', 'Refresh-Token', 'Token'],
             methods: %i[get post put patch delete]
  end
end

