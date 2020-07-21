class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy, :edit_basic_info, :update_basic_info]
  before_action :logged_in_user, only: [:index, :show, :edit, :update, :destroy, :edit_basic_info, :update_basic_info]
  before_action :correct_user, only: [:edit, :update]
  before_action :admin_user, only: [:index, :destroy, :edit_basic_info, :update_basic_info]
  before_action :admin_or_correct_user, only: [:show, :edit, :update]
  before_action :set_one_month, only: :show
  
  def index
    @users = User.all
  end
  
  # CSVインポート
  def import
    if params[:csv_file].blank?
      flash[:danger] = '読み込むCSVを選択してください。'
    elsif File.extname(params[:csv_file].original_filename) != ".csv"
      flash[:danger] = 'csvファイルのみ読み込み可能です。'
    else
      num = User.import_by_csv(params[:csv_file])
      flash[:success] = "#{ num.to_s }件のデータ情報を追加/更新しました。"
    end
    redirect_to action: 'index'
  end
  
  # 出勤中社員一覧
  def working_members
    @users = User.includes(:attendances).references(:attendances).
      where('attendances.started_at IS NOT NULL').
      where('attendances.finished_at IS NULL')
  end
  
  # 勤怠ログ
  def attendance_log
    @user = User.find(params[:id])
    @first_day = Date.today.to_date.beginning_of_month
    @last_day = @first_day.end_of_month
    @attendances = @user.attendances.where(edit_status: "承認", worked_on: @first_day..@last_day).order(worked_on: "ASC")
  end
  
  def show
    @worked_sum = @attendances.where.not(started_at: nil).count
    @superiors = User.where(superior: true).where.not(id: @user.id)
    @overwork_notices = Attendance.where(overwork_request_status: "申請中", overwork_superior_confirmation: @user.name).count
    @attendance_notices = Attendance.where(edit_status: "申請中", edit_superior_confirmation: @user.name).count
    @monthly_notices = Attendance.where(monthly_status: "申請中", monthly_superior_confirmation: @user.name).count
    @monthly_attendance = @user.attendances.find_by(worked_on: @first_day)
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
  
  # 所属長承認ボタン
  def superior_apploval
    @user = User.find(params[:id])
    @attendance = @user.attendances.find_by(worked_on: params[:user][:first_day])
    if params[:user][:monthly_superior_confirmation].present?
      @attendance.monthly_status = "申請中"
      @attendance.update_attributes(monthly_approval_params)
      flash[:success] = "1ヶ月の勤怠を申請しました。"
    else
      flash[:danger] = "所属長を入力して下さい。"
    end
    redirect_to @user
  end
  
  private
  
    def user_params
      params.require(:user).permit(:name, :email, :affiliation, :password, :password_confirmation)
    end
    
    def basic_info_params
      params.require(:user).permit(:name, :email, :affiliation, :employee_number, :uid, :basic_work_time, :designated_work_start_time, :designated_work_end_timework_end_tim)
    end
    
    def monthly_approval_params
      params.require(:user).permit(:monthly_superior_confirmation)
    end
end
