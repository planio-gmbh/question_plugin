module QuestionPlugin
  class ViewHooks < Redmine::Hook::ViewListener

    render_on :view_journals_notes_form_after_notes,
      :partial => 'hooks/question_plugin/journals_notes_form_after_notes'

    render_on :view_journals_update_js_bottom,
      :partial => 'hooks/question_plugin/journals_update_js_bottom'

    render_on :view_issues_history_journal_bottom,
      :partial => 'hooks/question_plugin/issues_history_journal_bottom'

    render_on :view_issues_edit_notes_bottom,
      :partial => 'hooks/question_plugin/issues_edit_notes_bottom'

    render_on :view_issues_sidebar_issues_bottom,
      partial: 'hooks/question_plugin/issues_sidebar_issues_bottom'

    def view_layouts_base_html_head(context = { })
      <<-CSS
        <style type="text/css">
          .question { background-color:#FFEBC1; border:2px solid #FDBD3B; margin-bottom:12px; padding:0px 4px 8px 4px; }
          td.formatted_questions { text-align: left; white-space: normal}
          td.formatted_questions ol { margin-top: 0px; margin-bottom: 0px; }

          .kanban-question { background:#FFFFFF none repeat scroll 0 0; border:1px solid #D5D5D5; padding:2px; font-size: 0.8em }
          .question-link {font-weight: bold; } /* Kanban Menu item */

        </style>
      CSS
    end

    def controller_issues_edit_before_save(context = { })
      params = context[:params]
      journal = context[:journal]
      if params[:note] && !params[:note][:question_assigned_to].blank?
        unless journal.question # Update handled by Journal hooks
          # New
          journal.question = Question.new(
                                          :author => User.current,
                                          :issue => journal.issue
                                         )
          if params[:note][:question_assigned_to] != 'anyone'
            # Assigned to a specific user
            journal.question.assigned_to = User.find_by_id(params[:note][:question_assigned_to])
          end
        end
      end
    end


    def controller_journals_edit_post(context = { })
      journal = context[:journal]
      params = context[:params]

      # Handle destroying journals through the 'edit' action (done by clearing notes)
      return '' if journal.destroyed?

      if params[:question]
        name = params[:question][:assigned_to_name]
        id = params[:question][:assigned_to]
        if journal.question
          if name.blank?
            # Wants to remove the question
            journal.question.destroy
          elsif journal.question.opened?
            # Reassignment
            if id == 'anyone'
              journal.question.update_attributes(:assigned_to => nil)
            else
              journal.question.update_attributes(:assigned_to => User.find_by_id(id))
            end
          elsif !journal.question.opened
            # Existing question, destry it first and then add a new question
            journal.question.destroy
            add_new_question(journal, User.find_by_id(id))
          end
        elsif id == 'anyone'
          add_new_question(journal)
        elsif id.present?
          add_new_question(journal, User.find_by_id(id))
        else
          # No question
        end

      end

      return ''
    end


    private

    def add_new_question(journal, assigned_to = nil)
      journal.question = Question.new(:author => User.current,
                                      :issue => journal.issue,
                                      :assigned_to => assigned_to)
      journal.question.save!
      journal.save
    end
  end
end
