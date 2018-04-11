# frozen_string_literal: true

Rails.application.routes.draw do
  post :sing_up, controller: :api
  post :sing_in, controller: :api

  post :check_user, controller: :api
  post :repeat_confirmation, controller: :api
  post :recovery_password, controller: :api
  post :confirm_recovery, controller: :api

  post :confirm_registration, controller: :api
  post :change_password, controller: :api

  post :take_access_token, controller: :api
  post :user_update, controller: :api
  post :user_info, controller: :api
end
