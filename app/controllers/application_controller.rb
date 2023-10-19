# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :require_login

  private

  def not_authenticated
    redirect_to new_session_path, danger: "ログインしてください"
  end

  def admin?
    unless current_user.role == "管理者"
      redirect_to invoices_path, notice: "許可されていないアクセスです"
    end
  end
  
end
