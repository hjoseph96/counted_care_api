class RemoveCaregiverIdFromCareRecipients < ActiveRecord::Migration[8.0]
  def change
    remove_column :care_recipients, :caregiver_id
  end
end
