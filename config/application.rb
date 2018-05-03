require_relative 'boot'

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"
# require "sprockets/railtie"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module TrackingCoinsRails
  class Application < Rails::Application
    config.load_defaults 5.1
    config.active_record.record_timestamps = false
    config.api_only = true

    Dotenv::Railtie.load

    config.active_job.queue_adapter = :sidekiq
    config.autoload_paths << "#{Rails.root}/lib"
  end
end
