class FarmsMonitoringJob < ApplicationJob
  require 'net/http'

  include Nanopool

  def perform
    nanopool
  end
end
