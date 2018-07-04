# frozen_string_literal: true

module Auth
  include SendgridMailer
  include Coinmarketcap
  include Yobit
  include AdditionalForExchanges


  include CheckNotifications
  include Binance
  include Hitbtc
  include Livecoin
  include Exmo
  include Bittrex
  include Bitstamp
  include Cex
  include Bitsane
  include Okcoin

  include Nanopool

  def test
    render json: { check: nanopool }
  end

  def root; end

  def check_user
    where = params[:email] \
      ? { email: params[:email] } \
      : { telegram_username: params[:telegram_username] }
    render json: { check: !user_find(where).nil? }
  end

  def sign_in
    data = 200, { }

    where = params[:email] \
      ? { email: params[:email] } \
      : { telegram_username: params[:telegram_username] }

    field_activated = params[:email] ? :email_activated : :telegram_activated

    if (user = user_find(where)) &&
       user.authenticate(params[:password]) &&
       user[field_activated]

      header_tokens(user: user)
      data = { user: user_for_api(user: user) }
    else
      status, data = 403, { error: 'FAIL_AUTH' }
    end

    render json: data, status: status
  end

  def sign_up
    email = params[:email]
    status, data = 200, { }

    if user_find(email: email)
      status = 400, { error: 'FAIL_EMAIL_EXISTS' }
    else
      par = params.permit(:username, :email, :password).merge(lang: current_lang, telegram_activated: false)
      user = User.create(par)
      if send_confirmation(user_id: user.id, email: email, lang: current_lang)
        user.destroy
        status, data = 400, { error: 'FAIL_SEND' }
      end
    end

    render json: data, status: status
  end

  def repeat_confirmation
    email = params[:email]
    status, data = 200, { }

    if (user = user_find(email: email)) && !user.email_activated
      if send_confirmation(user_id: user.id, email: email, lang: current_lang)
        status, data = 400, { error: 'FAIL_SEND' }
      end
    else
      status, data = 400, { error: 'FAIL_EMAIL_NOT_EXISTS' }
    end

    render json: data, status: status
  end

  def confirm_registration
    token = decode_token(bearer_token)
    status, data = 200, { }

    if token && token['type'] == 'registration'
      user = user_find(id: token['user'])
      user.update(email_activated: true, email_enabled: true)

      header_tokens(user: user)
      data = { user: user_for_api(user: user) }
    else
      status, data = 403, { error: 'FAIL_CONFIRM' }
    end

    render json: data, status: status
  end

  def recovery_password
    email = params[:email]
    status, data = 200, { }

    if (user = user_find(email: email))
      if send_recovery(user_id: user.id, email: email, lang: current_lang)
        status, data = 400, { error: 'FAIL_SEND' }
      end
    else
      status, data = 400, { error: 'FAIL_EMAIL_NOT_EXISTS' }
    end

    render json: data, status: status
  end

  def confirm_recovery
    token = decode_token(bearer_token)
    status, data = 200, { }

    unless token && token['type'] == 'recovery'
      status, data = 403, { error: 'FAIL_RECOVERY' }
    end

    render json: data, status: status
  end

  def change_password
    token = decode_token(bearer_token)
    status, data = 200, { }

    if token && token['type'] == 'recovery'
      user = user_find(id: token['user'])
      user.update(password: params[:password])

      header_tokens(user: user)
      { user: user_for_api(user: user) }
    else
      status, data = 403, { error: 'FAIL_CHANGE_PASSWORD' }
    end

    render json: data, status: status
  end

  def take_access_token
    token_encode = bearer_token
    status = 200

    if (token = decode_token(token_encode)) && token['type'] == 'refresh'
      user = user_find(id: token['user'])

      if user.refresh_token == token_encode
        header_tokens(user: user)
      else
        status = 401
      end
    else
      status = 401
    end

    render json: { }, status: status
  end

  def get_currencies
    coinmarketcap
    yobit_pairs
    render json: { status: true }
  end

  private

  def user_find(where)
    @user ||= User.find_by(where)
  end

  def header_tokens(user:)
    response.set_header('Access-Token', access_token(user_id: user.id))
    response.set_header('Refresh-Token', user.set_refresh_token)
  end

  def current_lang
    lang = request.headers['Accept-Language']
    (/^(en|ru)/.match(lang) || 'en').to_s.to_sym
  end
end
