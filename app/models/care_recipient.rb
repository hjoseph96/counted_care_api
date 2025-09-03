class CareRecipient < ApplicationRecord
  belongs_to :user
  has_many :expenses, dependent: :destroy
  
  validates :name, presence: true
  validates :relationship, presence: true
end
