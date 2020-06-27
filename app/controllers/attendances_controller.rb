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
  
  # 残業申請モーダル
  def edit_overwork_request
    @user = User.find(params[:user_id])
    @attendance = @user.attendances.find(params[:id])
    @instructors = User.where(instructor: true).where.not(id: @user.id)
  end
  
  # 残業申請モーダル更新
  def update_overwork_request
    @user = User.find(params[:user_id])
    @attendance = @user.attendances.find(params[:id])
    if params[:attendance][:work_details].blank? || params[:attendance][:overwork_instructor_confirmation].blank?
      flash[:danger] = "未入力の項目があります。"
    else
      @attendance.overwork_request_status = "申請中"
      @attendance.update_attributes(overwork_params)
      flash[:success] = "残業を申請しました。"
    end
    redirect_to @user
  end

  # 残業申請お知らせモーダル
  def edit_notice_overwork
    @user = User.find(params[:user_id])
    @attendances = Attendance.where(overwork_request_status: "申請中").order(user_id: "ASC", worked_on: "ASC").group_by(&:user_id)
  end
  
  # 残業申請お知らせモーダル更新
  def update_notice_overwork
    @user = User.find(params[:user_id])
    ActiveRecord::Base.transaction do
      overwork_notice_params.each do |id, item|
        # if item[:overwork_request_status] == "申請中" || item[:change] == "0"
        #   flash[:danger] = "無効な入力データがあった為、変更をキャンセルしました。"
        #   redirect_to @user and return
        # end
        if item[:change] == "1" && item[:overwork_request_status].in?(["承認", "否認"])
          attendance = Attendance.find(id)
          attendance.update_attributes!(item)
        end
      end
    end
    flash[:success] = "変更を送信しました。"
    redirect_to @user and return
  rescue ActiveRecord::RecordInvalid
    flash[:danger] = "無効な入力データがあった為、変更をキャンセルしました。"
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
    
    # 残業申請お知らせの更新情報
    def overwork_notice_params
      params.require(:user).permit(attendances: [:overwork_request_status, :change])[:attendances]
    end
end
