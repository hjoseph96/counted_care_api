class CreateExpenses < ActiveRecord::Migration[8.0]
  def change
    create_table :expenses, id: :uuid do |t|
      t.integer :amount
      t.datetime :date
      t.string :category
      t.string :subcategory, null: true
      t.string :description, null: true
      t.string :receipt_url, null: true
      t.text :expense_tags, array: true, default: []
      t.boolean :is_tax_deductible, null: true
      t.boolean :is_reimbursed, null: true
      t.boolean :is_potentially_deductible, null: true
      t.string :reimbursement_source, null: true
      t.string :synced_transaction_id, null: true
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :care_recipient, null: false, foreign_key: true, type: :uuid
      t.text :notes, null: true

      t.timestamps
    end
    add_index :expenses, :amount
    add_index :expenses, :date
    add_index :expenses, :category
  end
end
