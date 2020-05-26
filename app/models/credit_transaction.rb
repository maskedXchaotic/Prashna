class CreditTransaction < ApplicationRecord
  enum transaction_type: { signup: 0, purchase: 1, debit: 2, popular: 3, revert: 4 }

  belongs_to :user

  before_save :set_transaction_credit_balance
  after_commit :set_user_credit_balance

  private def set_transaction_credit_balance
    self.credit_balance = self.user.credit_balance + self.amount
  end

  private def set_user_credit_balance
    user.refresh_credits!
  end

  def revert
    CreditTransaction.create(amount: -self.amount, transaction_type: "revert", user: user)
  end
end
