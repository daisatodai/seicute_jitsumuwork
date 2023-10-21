class RequestorsController < ApplicationController
  before_action :admin?, only: %i[edit update destroy]

  def index
    @requestors = Requestor.all
    @requestors = @requestors.page(params[:page]).per(15)

  end

  def new
    @requestor = Requestor.new
  end

  def create
    @requestor = Requestor.new(requestor_params)
    if @requestor.save
      flash[:success] = "#{@requestor.name}を登録しました"
      redirect_to requestors_path
    else
      flash.now[:danger] = "請求元の登録に失敗しました"
      render :new
    end
  end

  def edit
    @requestor = Requestor.find(params[:id])
  end

  def update
    @requestor = Requestor.find(params[:id])
    if @requestor.update(requestor_params)
      flash[:success] = "#{@requestor.name}に更新しました"
      redirect_to requestors_path
    else
      flash.now[:danger] = "更新に失敗しました"
      render :edit
    end
  end

  def destroy
    @requestor = Requestor.find(params[:id])
    if @requestor.destroy
      flash[:success] = "#{@requestor.name}を削除しました"
      redirect_to requestors_path
    else
      flash.now[:danger] = "削除に失敗しました"
      render :index
    end
  end

  def requestor_new
    if params[:new_requestor_name].present?
      @requestor = Requestor.new(name: params[:new_requestor_name])
      @requestor.save
    end
  end

  private

  def requestor_params
    params.require(:requestor).permit(:name)
  end
end
