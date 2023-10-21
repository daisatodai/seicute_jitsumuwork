# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :require_login

  private

  def not_authenticated
    flash[:danger] = "ログインしてください"
    redirect_to new_session_path
  end

  def admin?
    unless current_user.role == "管理者"
      flash[:danger] = "許可されていないアクセスです"
      redirect_to invoices_path
    end
  end
  
end
