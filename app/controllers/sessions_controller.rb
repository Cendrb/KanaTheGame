class SessionsController < ApplicationController
  def new
  end

  def create
    if user = User.authenticate(params[:email], params[:password])
      if params[:permanent]
        cookies.permanent.signed[:user_id] = user.id
      end
      session[:user_id] = user.id
      redirect_to root_path
    else
      respond_to do |format|
        format.html {redirect_to login_url, alert: "Neplatné jméno nebo heslo!"}
      end

    end
  end

  def destroy
    cookies.delete :user_id
    session[:user_id] = nil
    redirect_to root_path, notice: 'Uživatel byl odhlášen'
  end
end
