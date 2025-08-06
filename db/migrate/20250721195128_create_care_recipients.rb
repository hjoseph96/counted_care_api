class CreateCareRecipients < ActiveRecord::Migration[8.0]
  def change
    create_table :care_recipients, id: :uuid do |t|
      t.string :name
      t.string :relationship
      t.text :conditions, array: true, null: true
      t.string :insurance_info, null: true

      t.timestamps
    end
  end
end
