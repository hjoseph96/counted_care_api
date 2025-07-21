class Expense < ApplicationRecord
  belongs_to :care_recipient
  belongs_to :user
  belongs_to :care_recipient
end
