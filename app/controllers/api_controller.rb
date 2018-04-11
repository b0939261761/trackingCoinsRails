# frozen_string_literal: true

# Main module Api
class ApiController < ApplicationController
  include Auth
  include Token

  private

  def bearer_token
    pattern = /^Bearer /
    header = request.headers['Authorization']
    header.gsub(pattern, '') if header&.match(pattern)
  end
end
