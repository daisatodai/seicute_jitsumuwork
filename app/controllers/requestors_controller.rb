class RequestorsController < ApplicationController

  def index
    @requestors = Requestor.all
  end

  def new
    @requestor = Requestor.new
  end

  def create
    @requestor = Requestor.new(requestor_params)
    if @requestor.save
      flash[:success] = "請求元を登録しました"
      redirect_to new_invoice_path
    else
      flash[:danger] = "請求元の登録に失敗しました"
      render :new
    end
  end

  private

  def requestor_params
    params.require(:requestor).permit(:name)
  end

end
