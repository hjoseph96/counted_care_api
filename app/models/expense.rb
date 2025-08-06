class Expense < ApplicationRecord
  belongs_to :user
  belongs_to :care_recipient, optional: true
end
