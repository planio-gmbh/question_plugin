class QuestionKanbanHooks  < Redmine::Hook::ViewListener
  # Have to inclue Gravatars because ApplicationHelper will not get it
  include GravatarHelper::PublicMethods

  # Adds a link showing the questions for the current user
  def view_user_kanbans_show_contextual_top(context={})
    user = User.current
    if user
      count = Question.count_of_open_for_user(user)

      if count > 0
        return link_to(l(:field_formatted_questions) + " (#{count})",
                       {
                         :controller => 'questions',
                         :action => 'user_issue_filter',
                         :user_id => user.id,
                         :only_path => true
                       }, { :class => 'question-link' })
      end
    end
  end

  def view_kanbans_issue_details(context = {})
    # GREY when there are no questions
    # RED when there are open questions
    # BLACK if all questions are answered
    issue = context[:issue]

    return '' unless issue

    if issue.questions.count == 0
      return question_icon(:gray, issue)
    end

    if issue.questions.open.count > 0
      return question_icon(:red, issue)
    end

    if issue.questions.count > 0 && issue.questions.open.count == 0
      return question_icon(:black, issue)
    end

    return ''
  end

  # * :user
  def view_kanbans_user_name(context = {})
    user = context[:user]
    if user
      count = Question.count_of_open_for_user(user)

      if count > 0
        return content_tag(:p, link_to(l(:field_formatted_questions) + " (#{count})",
                                       {
                                         :controller => 'questions',
                                         :action => 'user_issue_filter',
                                         :user_id => user.id,
                                         :only_path => true
                                       },
                                       { :class => 'question-link' }))
      end
    end

    return ''

  end

  protected

  def question_icon(color, issue)
    total_questions = issue.questions.count
    open_questions = issue.questions.open.count
    answered_questions = total_questions - open_questions

    title = l(:question_text_ratio_questions_answered, :ratio => "#{answered_questions}/#{total_questions}")
    link_to(image_tag("question-#{color}.png", :plugin => 'question_plugin', :title => title, :class => "kanban-question #{color}"),
            { :controller => 'issues', :action => 'show', :id => issue },
            :class => "issue-show-popup issue-id-#{h(issue.id)}")
  end

  def assigned_question_html(question)
    html = "<span class=\"question-line\">"
    html << "  <a name=\"question-#{h(question.id)}\" href=\"#question-#{h(question.id)}\">"
    html << "#{l(:text_question_for)} #{question.assigned_to.to_s}"
    html << "  </a>"
    html << "<span>#{avatar(question.assigned_to, { :size => 16, :class => '' })}</span> </span>" if question.assigned_to && question.assigned_to.mail
    html
  end

  def unassigned_question_html(question)
    html = "<span class=\"question-line\">"
    html << "  <a name=\"question-#{h(question.id)}\" href=\"#question-#{h(question.id)}\">"
    html << l(:text_question_for_anyone)
    html << "  </a>"
    html << "</span>"
    html
  end
end
