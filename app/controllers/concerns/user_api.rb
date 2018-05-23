# frozen_string_literal: true

# Access to site
module UserApi
  def user_update
    par = params.permit(:username, :email, :password, :lang, :email_enabled,
      :telegram_username, :telegram_enabled, :telegram_activated)

    unless par[:telegram_activated]
      par.merge(telegram_first_name: '', telegram_last_name: '', telegram_chat_id: 0)
    end

    user = User.find(user_id)
    user.update(par)
    render json: { user: user_for_api(user: user) }
  end

  def user_info
    render json: { user: user_for_api(user: User.find(user_id)) }
  end

  def user_remove
    User.find(user_id).destroy
    render json: { }
  end
end
