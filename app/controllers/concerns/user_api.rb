# frozen_string_literal: true

# Access to site
module UserApi
  def user_update
    par = params.permit(:username, :email, :password, :lang)

    user = User.update(user_id, par)
    render json: { user: user_for_api(user: user) }
  end

  def user_info
    render json: { user: user_for_api(user: User.find(user_id)) }
  end

  def user_remove
    User.find(user_id).destroy
    render json: {}
  end
end
