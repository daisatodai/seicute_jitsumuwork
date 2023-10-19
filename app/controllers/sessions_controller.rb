class SessionsController < ApplicationController
  skip_before_action :require_login, only: %i[create new]

  def new
    redirect_to root_path if view_context.logged_in?
  end

  def create
    user = login(params[:email], params[:password])
    if user
      name = current_user.email.match(/(.*)@/)[1]
      redirect_back_or_to root_path, notice: "おかえりなさい、#{name}さん"

    else
      flash.now[:danger] = "ログインに失敗しました"
      render :new
    end
  end

  def destroy
    logout
    redirect_to new_session_path, notice: 'ログアウトしました'
  end

end
