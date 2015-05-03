class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # You should configure your model like this:
  # devise :omniauthable, omniauth_providers: [:twitter]

  # You should also create an action method in this controller like this:
  # def twitter
  # end
  def yahoo
    omniauth_hash = request.env['omniauth.auth']
    @user = User.initialize_from_auth_hash(omniauth_hash)
    sign_in @user
    # if user.save
      # # sign_in user
      # flash[:notice] = "IT WORKED"
    # else
      # flash[:notice] = "SOMETHING WENT WRONG"
    # end
    # render "homes/index"
    redirect_to root_path
  end

  # More info at:
  # https://github.com/plataformatec/devise#omniauth

  # GET|POST /resource/auth/twitter
  # def passthru
  #   super
  # end

  # GET|POST /users/auth/twitter/callback
  # def failure
  #   super
  # end

  # protected

  # The path used when omniauth fails
  # def after_omniauth_failure_path_for(scope)
  #   super(scope)
  # end
end
