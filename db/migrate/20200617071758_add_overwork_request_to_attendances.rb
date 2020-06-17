class AddOverworkRequestToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :scheduled_end_time, :datetime
    add_column :attendances, :next_day, :boolean
    add_column :attendances, :work_details, :string
  end
end
