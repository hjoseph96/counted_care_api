class AddUserIdToCareRecipients < ActiveRecord::Migration[8.0]
  def up
    # First add the column as nullable
    add_reference :care_recipients, :user, null: true, foreign_key: true, type: :uuid
    
    # Get the first user (or create one if none exists)
    user = User.first
    if user.nil?
      user = User.create!(
        email: 'admin@example.com',
        password: 'password123',
        name: 'Admin User'
      )
    end
    
    # Update existing care_recipients to belong to this user
    execute "UPDATE care_recipients SET user_id = '#{user.id}' WHERE user_id IS NULL"
    
    # Now make the column non-nullable
    change_column_null :care_recipients, :user_id, false
  end

  def down
    remove_reference :care_recipients, :user, foreign_key: true
  end
end
