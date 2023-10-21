class UsersController < ApplicationController
  before_action :admin?

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      flash[:success] = "#{get_name_from_email}さんを作成しました"
      redirect_to users_path
    else
      flash[:danger] = "ユーザーの作成に失敗しました"
      render :new
    end
  end

  def index
    @users = User.all
    @users = @users.page(params[:page]).per(15)
  end

  def edit
    @user = User.find(params[:id])

  end

  def update
    @user = User.find(params[:id])
    if @user.update(user_params)
      flash[:success] = "#{get_name_from_email}さんを更新しました"
      redirect_to users_path
    else
      flash.now[:danger] = "ユーザーの更新に失敗しました"
      render :edit
    end
  end

  def destroy
    @user = User.find(params[:id])
    if @user.destroy
      flash[:success] = "#{get_name_from_email}さんを削除しました"
      redirect_to users_path
    else
      if current_user.id == @user.id
        flash[:danger] = "管理者は最低1名必要です"
        redirect_to users_path
      else
        flash[:danger] = "ユーザーの削除に失敗しました"
        redirect_to users_path
      end
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :role)
  end

  def get_name_from_email
    name = @user.email.match(/(.*)@/)[1]
  end
end