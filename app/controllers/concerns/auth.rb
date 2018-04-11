# frozen_string_literal: true

# Access to site
module Auth
  include SendgridMailer

  EMAIL_EXISTS = 4061
  EMAIL_NOT_EXISTS = 4062

  def check_user
    render json: { status: !get_user_by_email(email: params[:email]).nil? }
  end

  def sing_in
    render json:
      if (user = get_user_by_email(email: params[:email])) &&
         user.authenticate(params[:password]) &&
         user.confirmed

        header_tokens(user: user)
        { status: true, user: user_for_api(user: user) }
      else
        { status: false }
      end
  end

  def sing_up
    email = params[:email]
    render json:
      if get_user_by_email(email: email)
        { status: false, error: EMAIL_EXISTS }
      else
        par = params.permit(:username, :email, :password).merge(lang: current_lang)
        user = User.create(par)
        send_confirmation(user_id: user.id, email: email, lang: current_lang)
      end
  end

  def repeat_confirmation
    email = params[:email]
    render json:
      if (user = get_user_by_email(email: email)) && !user.confirmed
        send_confirmation(user_id: user.id, email: email, lang: current_lang)
      else
        { status: false, error: EMAIL_NOT_EXISTS }
      end
  end

  def confirm_registration
    token = decode_token(bearer_token)

    render json:
      if token && token['type'] == 'registration'
        user = get_user_by_id(id: token['user'])
        user.update(confirmed: true)

        header_tokens(user: user)
        { status: true, user: user_for_api(user: user) }
      else
        { status: false }
      end
  end

  def recovery_password
    email = params[:email]
    render json:
      if (user = get_user_by_email(email: email))
        send_recovery(user_id: user.id, email: email, lang: current_lang)
      else
        { status: false, error: EMAIL_NOT_EXISTS }
      end
  end

  def confirm_recovery
    token = decode_token(bearer_token)

    render json:
      if token && token['type'] == 'recovery'
        { status: true }
      else
        { status: false }
      end
  end

  def change_password
    token = decode_token(bearer_token)

    render json:
      if token && token['type'] == 'recovery'
        user = get_user_by_id(id: token['user'])
        user.update(password: params[:password])

        header_tokens(user: user)
        { status: true, user: user_for_api(user: user) }
      else
        { status: false }
      end
  end

  def take_access_token
    token_encode = bearer_token

    render json:
      if (token = decode_token(token_encode)) && token['type'] == 'refresh'
        user = get_user_by_id(id: token['user'])
        if user.refresh_token == token_encode
          header_tokens(user: user)
          { status: true }
        else
          { status: false }
        end
      else
        { status: false }
      end
  end

  def user_update
    token_encode = bearer_token

    render json:
      if (token = decode_token(token_encode)) && token['type'] == 'access'
        par = params.permit(:username, :email, :password, :lang)

        user = User.update(token['user'], par)
        { status: true, user: user_for_api(user: user) }
      else
        { status: false }
      end
  end

  def user_info
    token_encode = bearer_token

    render json:
      if (token = decode_token(token_encode)) && token['type'] == 'access'
        user = User.find(token['user'])
        { status: true, user: user_for_api(user: user) }
      else
        { status: false }
      end
  end

  private

  def get_user_by_email(email:)
    @user = User.find_by(email: email)
  end

  def get_user_by_id(id:)
    @user = User.find(id)
  end

  def header_tokens(user:)
    response.set_header('Access-Token', access_token(user_id: user.id))
    response.set_header('Refresh-Token', user.set_refresh_token)
  end

  def current_lang
    lang = request.headers['Accept-Language']
    (/^(en|ru)/.match(lang) || 'en').to_s.to_sym
  end

  def user_for_api(user:)
    user.slice(:username, :email, :lang)
  end
end
