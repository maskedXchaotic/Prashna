# == Schema Information
#
# Table name: answers
#
#  id                         :bigint           not null, primary key
#  body                       :text(65535)
#  user_id                    :bigint           not null
#  question_id                :bigint           not null
#  reaction_count             :integer          default(0)
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  popularity_credits_granted :boolean          default(FALSE)
#  published                  :boolean          default(TRUE)
#  marked_abused              :boolean          default(FALSE)
#
class Answer < ApplicationRecord
  include ReactionRecorder
  include Reported
  include Posted
  include BasicPresenter::Concern

  validates :body, presence: true
  validates :question_id, uniqueness: { scope: :user_id }
  validate :question_is_published
  validate :not_published_if_marked_abusive

  belongs_to :user
  belongs_to :question
  has_many :reactions, as: :reactable, dependent: :restrict_with_error
  has_many :comments, as: :commentable, dependent: :restrict_with_error
  has_many :credit_transactions, as: :transactable
  has_many :abuse_reports, as: :abuseable

  after_commit :notify_question_author, on: :create

  scope :order_by_vote, -> {order(reaction_count: :desc)}
  default_scope { where(published: true) }


  def refresh_votes!
    self.reaction_count = reactions.upvotes.count -  reactions.downvotes.count
    check_popularity
    save!
  end

  private def check_popularity
    if reaction_count >= ENV["popular_question_votes"].to_i && !popularity_credits_granted
      grant_credits
      self.popularity_credits_granted = true
    end

    if reaction_count < ENV["popular_question_votes"].to_i && popularity_credits_granted
      revert_credits
      self.popularity_credits_granted = false
    end

  end

  private def grant_credits
    credit_transactions.popular.create(user: user, amount: ENV["popular_question_credits"].to_i)
  end

  private def revert_credits
    credit_transactions.popular.last.reverse_transaction
  end

  private def question_is_published
    if question.draft?
      errors.add(:base, "Parent question is not published")
      throw :abort
    end
  end

  private def notify_question_author
    unless question.user == user
      UserMailer.send_question_answered_mail(self.id).deliver_later
    end
  end

  def mark_abusive!
    self.transaction do
      self.marked_abused = true
      unpublish!
    end
  end
  
  def unpublish!
    self.published = false
    if popularity_credits_granted?
      self.popularity_credits_granted = false
      revert_credits
    end
    save!
  end

  private def not_published_if_marked_abusive
    if marked_abused && published
      errors.add(:base, 'Cannot be published marked abused')
      throw :abort
    end
  end

end
