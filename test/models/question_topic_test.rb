# == Schema Information
#
# Table name: question_topics
#
#  id          :bigint           not null, primary key
#  question_id :bigint           not null
#  topic_id    :bigint           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
require 'test_helper'

class QuestionTopicTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
