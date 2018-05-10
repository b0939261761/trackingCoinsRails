# redis = { url: ENV['REDIS_PROVIDER'], password: ENV['REDIS_PASSWORD'] }
redis = { url: ENV['REDIS_PROVIDER'] }

Sidekiq.configure_server do |config|
  config.redis = redis

  schedule_file = 'config/schedule.yml'
  if File.exist?(schedule_file)
    Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file)
  end
end

Sidekiq.configure_client do |config|
  config.redis = redis
end
