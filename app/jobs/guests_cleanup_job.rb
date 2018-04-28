class GuestsCleanupJob < ApplicationJob
  queue_as :default

  def perform(*args)
    p 'job============================================'
    sleep 5
  end
end
