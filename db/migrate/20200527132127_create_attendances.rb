class CreateAttendances < ActiveRecord::Migration[5.1]
  def change
    create_table :attendances do |t|
      t.date :worked_on
      t.datetime :started_at
      t.datetime :finished_at
      t.string :note
      t.references :user, foreign_key: true
      # 残業申請
      t.datetime :scheduled_end_time # 終了予定時間
      t.boolean :overwork_next_day # 翌日チェックボックス
      t.string :work_details # 業務処理内容
      t.string :overwork_request_status # 残業申請の状態
      t.string :overwork_superior_confirmation # 残業申請指示者確認
      t.boolean :change # 変更のチェックボックス
      # 勤怠編集
      t.datetime :edit_started_at # 変更申請用出社時間
      t.datetime :edit_finished_at # 変更申請用退社時間
      t.datetime :before_started_at # 変更前出社時間
      t.datetime :before_finished_at # 変更前退社時間
      t.boolean :next_day # 翌日チェックボックス
      t.string :edit_status # 勤怠編集の状態
      t.string :edit_superior_confirmation # 勤怠編集指示者確認
      t.date :approval_date # 承認日
      # 1ヶ月勤怠承認
      t.string :monthly_status # 1ヶ月承認の状態
      t.string :monthly_superior_confirmation # 1ヶ月承認指示者確認

      t.timestamps
    end
  end
end
