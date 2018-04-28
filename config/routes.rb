# frozen_string_literal: true

Rails.application.routes.draw do
  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'

  post :jobs, controller: :api
  post :sign_up, controller: :api
  post :sign_in, controller: :api

  post :check_user, controller: :api
  post :repeat_confirmation, controller: :api
  post :recovery_password, controller: :api
  post :confirm_recovery, controller: :api

  post :confirm_registration, controller: :api
  post :change_password, controller: :api

  post :take_access_token, controller: :api
  post :user_update, controller: :api
  post :user_info, controller: :api
  post :user_remove, controller: :api

  post :edit_notification, controller: :api
  post :remove_notification, controller: :api
  post :get_exchanges, controller: :api
  post :get_pairs, controller: :api
  post :get_notifications, controller: :api
end
