class SessionsController < ApplicationController
  skip_before_action :require_login, only: %i[create new guest_login guest_admin_login]

  def new
    redirect_to root_path if view_context.logged_in?
  end

  def create
    user = login(params[:email], params[:password])
    if user
      name = current_user.email.match(/(.*)@/)[1]
      flash[:info] = "おかえりなさい、#{name}さん"
      redirect_back_or_to root_path

    else
      flash.now[:danger] = "ログインに失敗しました"
      render :new
    end
  end

  def destroy
    logout
    flash[:info] = "ログアウトしました"
    redirect_to new_session_path
  end

  def guest_admin_login
    redirect_to root_path, alert: 'すでにログインしています' if current_user
    random_value = SecureRandom.hex
    user = User.create!(email: "test_#{random_value}@example.com", password: "#{random_value}", password_confirmation: "#{random_value}", role: 5)
    auto_login(user)
    flash[:info] = "ゲスト管理者としてログインしました"
    redirect_to root_path
  end

  def guest_login
    redirect_to root_path, alert: 'すでにログインしています' if current_user
    random_value = SecureRandom.hex
    user = User.create!(email: "test_#{random_value}@example.com", password: "#{random_value}", password_confirmation: "#{random_value}", role: 0)
    auto_login(user)
    flash[:info] = "ゲストとしてログインしました"
    redirect_to root_path
  end
end
