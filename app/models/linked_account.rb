class LinkedAccount < ApplicationRecord
  belongs_to :user

  enum :account_type, { bank: 0, fsa: 1, hsa: 2, credit_card: 3 }
end
