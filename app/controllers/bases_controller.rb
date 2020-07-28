class BasesController < ApplicationController
  before_action :set_base, only: [:show, :edit, :update, :destroy]
  
  def index
    @bases = Base.all
  end
  
  def show
  end
  
  def edit
  end
  
  def update
    if @base.update_attributes(base_params)
      flash[:success] = "拠点の更新に成功しました。"
      redirect_to bases_url and return
    elsif  params[:base_number].blank? || params[:base_name].blank?
      flash[:danger] = "拠点番号・拠点名を入力して下さい。"
      redirect_to edit_basis_url and return
    end
  end
  
  def create
  @base = Base.new(base_params)
    if @base.save
      flash[:info] = "拠点情報を追加しました。"
      redirect_to bases_url
    else 
      render :new
    end
  end
  
  def new
    @base = Base.new
  end 
  
  def destroy
    @base.destroy
    flash[:success] = "#{@base.base_name}のデータを削除しました。"
    redirect_to bases_url
  end
  
  
  private
  
  def base_params
      params.require(:base).permit(:base_number, :base_name, :base_type)
  end
end
