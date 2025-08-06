class LinkedAccount < ApplicationRecord
  belongs_to :user

  enum account_type: [ :bank, :fsa, :hsa, :credit_card ]
end
