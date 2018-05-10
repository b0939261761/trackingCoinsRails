# frozen_string_literal: true

# Access to site
module Auth
  include SendgridMailer
  include Coinmarketcap
  include CheckNotifications

  def test
  end

  def root; end

  def check_user
    render json: { check: !user_by_email(email: params[:email]).nil? }
  end

  def sign_in
    data = 200, { }

    if (user = user_by_email(email: params[:email])) &&
       user.authenticate(params[:password]) &&
       user.confirmed

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

    if user_by_email(email: email)
      status = 400, { error: 'FAIL_EMAIL_EXISTS' }
    else
      par = params.permit(:username, :email, :password).merge(lang: current_lang)
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

    if (user = user_by_email(email: email)) && !user.confirmed
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
      user = user_by_id(id: token['user'])
      user.update(confirmed: true)

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

    if (user = user_by_email(email: email))
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
      user = user_by_id(id: token['user'])
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
      user = user_by_id(id: token['user'])

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

  private

  def user_by_email(email:)
    @user ||= User.find_by(email: email)
  end

  def user_by_id(id:)
    @user ||= User.find(id)
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
