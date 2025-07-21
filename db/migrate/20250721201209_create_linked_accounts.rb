class CreateLinkedAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :linked_accounts, id: :uuid  do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.boolean :is_active
      t.integer :account_type
      t.string :account_name
      t.string :institution_name, null: true
      t.string :plaid_access_token, null: true
      t.string :plaid_account_id, null: true
      t.string :stripe_account_id, null: true
      t.string :access_token, null: true
      t.string :refresh_token, null: true
      t.datetime :last_sync_at, null: true

      t.timestamps
    end
    add_index :linked_accounts, :account_type
    add_index :linked_accounts, :is_active
  end
end
