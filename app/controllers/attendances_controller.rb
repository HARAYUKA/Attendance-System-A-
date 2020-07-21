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
  
  # 1ヶ月の勤怠編集
  def edit_one_month
    @superiors = User.where(superior: true).where.not(id: @user.id)
  end
  
  # 1ヶ月の勤怠更新
  def update_one_month
    ActiveRecord::Base.transaction do # トランザクションを開始します。
      attendances_params.each do |id, item|
        if item[:edit_superior_confirmation].present?
          if item[:edit_started_at].blank? || item[:edit_finished_at].blank? || item[:note].blank?
            flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
            redirect_to user_url(date: params[:date]) and return
          else
            item[:edit_status] = "申請中"
            attendance = Attendance.find(id)
            item[:edit_started_at] = attendance.worked_on.to_s + " " + item[:edit_started_at] + ":00"
            item[:edit_finished_at] = attendance.worked_on.to_s + " " + item[:edit_finished_at] + ":00"
            attendance.update_attributes!(item)
          end
        end
      end
    end
    flash[:success] = "勤怠変更申請を送信しました。"
    redirect_to user_url(date: params[:date]) and return 
  rescue ActiveRecord::RecordInvalid
    flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
    redirect_to attendances_edit_one_month_user_url(date: params[:date])
  end
  
  # 勤怠変更申請モーダル
  def change_att_request
    @user = User.find(params[:user_id])
    @attendances = Attendance.where(edit_status: "申請中", edit_superior_confirmation: @user.name).order(user_id: "ASC", worked_on: "ASC").group_by(&:user_id)
  end
  
  # 勤怠変更申請モーダル更新
  def update_att_request
    @user = User.find(params[:user_id])
    ActiveRecord::Base.transaction do
      change_att_params.each do |id, item|
        if item[:change] == "1"
          attendance = Attendance.find(id)
          if item[:edit_status] == "承認"
            if attendance.before_started_at.blank?
              attendance.before_started_at = attendance.started_at
            end
            if attendance.before_finished_at.blank?
              attendance.before_finished_at = attendance.finished_at
            end
            attendance.started_at = attendance.edit_started_at
            attendance.finished_at = attendance.edit_finished_at
            item[:change] = "0"
            item[:approval_date] = Date.current
            attendance.update_attributes!(item)
            flash[:success] = "変更を送信しました。"
          elsif item[:edit_status] == "否認"
            item[:change] = "0"
            attendance.update_attributes!(item)
          end
        end
      end
    end
    redirect_to @user and return
  rescue ActiveRecord::RecordInvalid
    flash[:danger] = "無効な入力データがあった為、変更をキャンセルしました。"
    redirect_to @user and return
  end
  
  # 残業申請モーダル
  def edit_overwork_request
    @user = User.find(params[:user_id])
    @attendance = @user.attendances.find(params[:id])
    @superiors = User.where(superior: true).where.not(id: @user.id)
  end
  
  # 残業申請モーダル更新
  def update_overwork_request
    @user = User.find(params[:user_id])
    @attendance = @user.attendances.find(params[:id])
    if params[:attendance][:work_details].blank? || params[:attendance][:overwork_superior_confirmation].blank?
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
    @attendances = Attendance.where(overwork_request_status: "申請中", overwork_superior_confirmation: @user.name).order(user_id: "ASC", worked_on: "ASC").group_by(&:user_id)
  end
  
  # 残業申請お知らせモーダル更新
  def update_notice_overwork
    @user = User.find(params[:user_id])
    ActiveRecord::Base.transaction do
      overwork_notice_params.each do |id, item|
        if item[:change] == "1"
          attendance = Attendance.find(id)
          if item[:overwork_request_status].in?(["承認", "否認"])
            item[:change] = "0"
            attendance.update_attributes!(item)
            flash[:success] = "変更を送信しました。"
          end
        end
      end
    end
    redirect_to @user and return
  rescue ActiveRecord::RecordInvalid
    flash[:danger] = "無効な入力データがあった為、変更をキャンセルしました。"
    redirect_to @user and return
  end
  
  # 1ヶ月の勤怠申請モーダル表示
  def edit_monthly
    @user = User.find(params[:user_id])
    @attendances = Attendance.where(monthly_superior_confirmation: @user.name).order(user_id: "ASC", worked_on: "ASC").group_by(&:user_id)
  end

  # 1ヶ月の勤怠申請モーダル更新
  def update_monthly
    @user = User.find(params[:user_id])
    ActiveRecord::Base.transaction do
      monthly_params.each do |id, item|
        if item[:change] == "1"
          attendance = Attendance.find(id)
          if item[:monthly_status] == "承認"
            item[:change] = "0"
            attendance.update_attributes!(item)
            flash[:success] = "申請を承認しました。"
          elsif item[:monthly_status] == "否認"
            item[:change] = "0"
            attendance.update_attributes!(item)
            flash[:danger] = "申請を否認しました。"
          end
        end
      end
    end
    redirect_to @user and return
  rescue ActiveRecord::RecordInvalid
    flash[:danger] = "無効な入力データがあった為、変更をキャンセルしました。"
    redirect_to @user and return
  end
  
  private
    # 1ヶ月分の勤怠情報を扱います。
    def attendances_params
      params.require(:user).permit(attendances: [:edit_started_at, :edit_finished_at, :note, :edit_superior_confirmation])[:attendances]
    end
    
    # 残業申請の更新情報
    def overwork_params
      params.require(:attendance).permit(:scheduled_end_time, :next_day, :work_details, :overwork_superior_confirmation)
    end
    
    # 残業申請お知らせの更新情報
    def overwork_notice_params
      params.require(:user).permit(attendances: [:overwork_request_status, :change])[:attendances]
    end
    
    # 勤怠変更申請の更新情報
    def change_att_params
      params.require(:user).permit(attendances: [:edit_status, :change, :approval_date])[:attendances]
    end
    
    # 1ヶ月の勤怠申請の更新情報
    def monthly_params
      params.require(:user).permit(attendances: [:monthly_status, :change])[:attendances]
    end
end
