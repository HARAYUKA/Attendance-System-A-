class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy, :edit_basic_info, :update_basic_info]
  before_action :logged_in_user, only: [:index, :show, :edit, :update, :destroy, :edit_basic_info, :update_basic_info]
  before_action :correct_user, only: [:edit, :update]
  before_action :admin_user, only: [:index, :destroy, :edit_basic_info, :update_basic_info]
  before_action :admin_or_correct_user, only: [:show, :edit, :update]
  before_action :set_one_month, only: :show
  
  def index
    @users = User.paginate(page: params[:page])
    if params[:search].present?
      @users = User.paginate(page: params[:page]).search(params[:search]) 
    end
    unless current_user?(@user) || current_user.admin?
      flash[:danger] = "閲覧権限がありません。"
      redirect_to(root_url)
    end
  end
  
  def show
    @worked_sum = @attendances.where.not(started_at: nil).count
    @instructors = User.where(instructor: true).where.not(id: @user.id)
    @overwork_notices = Attendance.where(overwork_request_status: "申請中", overwork_instructor_confirmation: @user.name).count
    @attendance_notices = Attendance.where(edit_status: "申請中", edit_instructor_confirmation: @user.name).count
    @monthly_notices = Attendance.where(monthly_status: "申請中", monthly_instructor_confirmation: @user.name).count
  end
  
  def new
    @user = User.new
  end
  
  def create
    @user = User.new(user_params)
    if @user.save
      log_in @user
      flash[:success] = "新規作成に成功しました。"
      redirect_to @user
    else
      render :new
    end
  end
  
  def edit
  end
  
  def update
    if @user.update_attributes(user_params)
      flash[:success] = "ユーザー情報を更新しました。"
      redirect_to @user
    else
      render :edit
    end
  end
  
  def destroy
    @user.destroy
    flash[:success] = "#{@user.name}のデータを削除しました。"
    redirect_to users_url
  end
  
  def edit_basic_info
  end

  def update_basic_info
    if @user.update_attributes(basic_info_params)
      flash[:success] = "#{@user.name}の基本情報を更新しました。"
    else
      flash[:danger] = "#{@user.name}の更新は失敗しました。<br>" + @user.errors.full_messages.join("<br>")
    end
    redirect_to users_url
  end
  
  # 勤怠確認ボタン
  def confirm_one_month
    attendance = Attendance.find(params[:attendance_id])
    @user = User.find(attendance.user_id)
    @first_day = attendance.worked_on.to_date.beginning_of_month
    @last_day = @first_day.end_of_month
    @attendances = @user.attendances.where(worked_on: @first_day..@last_day).order(:worked_on)
    @worked_sum = @attendances.where.not(started_at: nil).count
  end
  
  private
  
    def user_params
      params.require(:user).permit(:name, :email, :department, :password, :password_confirmation)
    end
    
    def basic_info_params
      params.require(:user).permit(:department, :basic_work_time, :work_start_time)
    end
end
