class SyncedTransaction < ApplicationRecord
  belongs_to :user
  belongs_to :linked_account
  belongs_to :expense
end
