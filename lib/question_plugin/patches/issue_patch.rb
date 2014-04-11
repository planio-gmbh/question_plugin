module QuestionPlugin
  module Patches

    module IssuePatch
      def self.included(base) # :nodoc:
        base.extend(ClassMethods)

        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable # Send unloadable so it will not be unloaded in development
          has_many :questions

          include ActionView::Helpers::TextHelper # for truncate
        end

      end

      module ClassMethods
      end

      module InstanceMethods
        def pending_question?(user)
          questions.opened.for_anyone.present? || questions.opened.for_user(user).present?
        end

        def close_pending_questions(user, closing_journal)
          questions.opened.each do |question|
            question.close!(closing_journal) if question.assigned_to == user || question.for_anyone?
          end
        end

        def formatted_questions
          questions.opened.collect do |question|
            truncate(question.journal.notes, length: Question::TruncateTo)
          end.join(", ")
        end
      end
    end

  end
end
