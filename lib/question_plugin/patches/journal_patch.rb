module QuestionPlugin
  module Patches

    module JournalPatch

      def self.included(base) # :nodoc:
        base.class_eval do
          has_one :question, :dependent => :destroy
          after_create :questions_after_create
        end
      end

      def question_assigned_to
        # TODO: pull out the assigned user on edits
      end

      def questions_after_create
        if question
          question.save
        elsif issue && issue.pending_question?(user)
          # Close any open questions
          issue.close_pending_questions(user, self)
        end
      end

    end
  end
end
