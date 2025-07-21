class CreateSyncedTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :synced_transactions, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :linked_account, null: false, foreign_key: true, type: :uuid
      t.references :expense, null: false, foreign_key: true, type: :uuid
      t.string :transaction_id
      t.datetime :date
      t.text :description
      t.string :merchant_name, null: true
      t.string :category, null: true
      t.boolean :is_potential_medical, null: true
      t.boolean :is_confirmed_medical, null: true
      t.boolean :is_tax_deductible, null: true
      t.boolean :is_reimbursed, null: true
      t.string :reimbursement_source, null: true

      t.timestamps
    end
    add_index :synced_transactions, :date
    add_monetize :synced_transactions, :amount

  end
end
