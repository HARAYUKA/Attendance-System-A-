class AttendancesController < ApplicationController
  before_action :set_user, only: [:edit_one_month, :update_one_month]
  before_action :logged_in_user, only: [:update, :edit_one_month, :edit_overwork_request, :update_overwork_request]
  before_action :admin_or_correct_user, only: [:update, :edit_one_month, :update_one_month]
  before_action :set_one_month, only: :edit_one_month
  
  UPDATE_ERROR_MSG = "勤怠登録に失敗しました。やり直してください。"

  def update
    @user = User.find(params[:user_id])
    @attendance = Attendance.find(params[:id])
    # 出勤時間が未登録であることを判定します。
    if @attendance.started_at.nil?
      if @attendance.update_attributes(started_at: Time.current.change(sec: 0))
        flash[:info] = "おはようございます！"
      else
        flash[:danger] = UPDATE_ERROR_MSG
      end
    elsif @attendance.finished_at.nil?
      if @attendance.update_attributes(finished_at: Time.current.change(sec: 0))
        flash[:info] = "お疲れ様でした。"
      else
        flash[:danger] = UPDATE_ERROR_MSG
      end
    end
    redirect_to @user
  end
  
  def edit_one_month
  end
  
  def update_one_month
    ActiveRecord::Base.transaction do # トランザクションを開始します。
      attendances_params.each do |id, item|
        if item[:finished_at].blank? && item[:started_at].present?
          flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
          redirect_to user_url(date: params[:date]) and return
        end
        attendance = Attendance.find(id)
        attendance.update_attributes!(item)
      end
    end
    flash[:success] = "１ヶ月分の勤怠情報を更新しました。"
    redirect_to user_url(date: params[:date]) and return 
  rescue ActiveRecord::RecordInvalid
    flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
    redirect_to attendances_edit_one_month_user_url(date: params[:date])
  end
  
  def edit_overwork_request
    @user = User.find(params[:user_id])
    @attendance = @user.attendances.find(params[:id])
  end
  
  def update_overwork_request
    @user = User.find(params[:user_id])
    @attendance = @user.attendances.find(params[:id])
    if params[:attendance][:work_details].blank? || params[:attendance][:overwork_instructor_confirmation].blank?
      flash[:danger] = "未入力の項目があります。"
    else
      @attendance.update_attributes(overwork_params)
      flash[:success] = "残業を申請しました。"
    end
    redirect_to @user
  end
 
  def edit_notice_overwork
    @user = User.find(params[:user_id])
    @notice_users = User.where(id: Attendance.where.not(scheduled_end_time: nil).select(:user_id))
  end
  
  def update_notice_overwork
    @user = User.find(params[:user_id])
  end

  
  private
    # 1ヶ月分の勤怠情報を扱います。
    def attendances_params
      params.require(:user).permit(attendances: [:started_at, :finished_at, :note])[:attendances]
    end
    
    # 残業申請の更新情報
    def overwork_params
      params.require(:attendance).permit(:scheduled_end_time, :next_day, :work_details, :overwork_instructor_confirmation)
    end
end
