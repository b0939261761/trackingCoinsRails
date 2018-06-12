# frozen_string_literal: true

# Main module Api
class ApiController < ApplicationController
  before_action :verify_valid?, except: Auth.instance_methods

  include Auth
  include UserApi
  include Token
  include Notifications

  private

  def check_token
    token = decode_token(bearer_token)
    token['user'] if token && token['type'] == 'access'
  end

  def user_id
    @user_id ||= check_token
  end

  def verify_valid?
    render status: 401 unless user_id
  end

  def bearer_token
    pattern = /^Bearer /
    header = request.headers['Authorization']
    header.gsub(pattern, '') if header&.match(pattern)
  end

  def user_for_api(user:)
    user
      .slice(:username, :email, :lang,
        :email_enabled, :email_activated,
        :telegram_username, :telegram_enabled, :telegram_activated)
      .merge(telegram_full_name: user.telegram_full_name)
  end
end
