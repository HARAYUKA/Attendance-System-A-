class Attendance < ApplicationRecord
  belongs_to :user
  
  validates :worked_on, presence: true
  validates :note, length: { maximum: 50 }
  
  # 出勤時間が存在しない場合、退勤時間は無効
  validate :finished_at_is_invalid_without_a_started_at
  
  # 出勤・退勤時間どちらも存在する時、出勤時間より早い退勤時間は無効
  # validate :started_at_than_finished_at_fast_if_invalid
  
  # 変更後（申請用）の出社・退社時間がどちらも存在する時、申請用の出勤時間より早い申請用の退勤時間は無効
  # validate :edit_started_at_than_edit_finished_at_fast_if_invalid

  def finished_at_is_invalid_without_a_started_at
    errors.add(:started_at, "が必要です") if started_at.blank? && finished_at.present?
  end
  
  # def started_at_than_finished_at_fast_if_invalid
  #   if started_at.present? && finished_at.present?
  #     errors.add(:started_at, "より早い退勤時間は無効です") if started_at > finished_at
  #   end
  # end
  
  # def edit_started_at_than_edit_finished_at_fast_if_invalid
  #   if (edit_started_at.present? && edit_finished_at.present?) && (next_day == "0")
  #     errors.add(:edit_started_at, "より早い退勤時間は無効です") if edit_started_at > edit_finished_at
  #   end
  # end  
end
