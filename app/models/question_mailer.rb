class QuestionMailer < Mailer
  unloadable

  def asked_question(journal)
    question = journal.question
    return unless question.assigned_to.present?

    redmine_headers 'Issue-Id' => question.issue.id
    redmine_headers 'Question-Asked' => question.author.login if question.author.present?
    redmine_headers 'Question-Assigned-To' => question.assigned_to.login if question.assigned_to.present?

    @question = question
    @issue = question.issue
    @journal = journal
    @users = @journal.recipients + @journal.watcher_recipients
    @issue_url = url_for(:controller => 'issues', :action => 'show', :id => question.issue)

    options = {
      to: question.assigned_to.mail,
      subject: "[Question #{question.issue.project.name} ##{question.issue.id}] #{question.issue.subject}"

    }
    options[:from] = "#{question.author.name} (Redmine) <#{Setting.mail_from}>" if question.author.present?
    Rails.logger.debug 'Sending QuestionMailer#asked_question'
    mail options
  end

  def answered_question(question, closing_journal)
    return if question.author.nil?

    redmine_headers 'Issue-Id' => question.issue.id
    redmine_headers 'Question-Answer' => "#{question.issue.id}-#{closing_journal.id}"

    options = {
      to: question.author.mail,
      subject:"[Answered #{question.issue.project.name} ##{question.issue.id}] #{question.issue.subject}"
    }
    options[:from] = "#{question.assigned_to.name} (Redmine) <#{Setting.mail_from}>" if question.assigned_to

    @question = question
    @issue = question.issue
    @journal = closing_journal
    @users = @journal.recipients + @journal.watcher_recipients
    @issue_url = url_for(:controller => 'issues', :action => 'show', :id => question.issue)

    Rails.logger.debug 'Sending QuestionMailer#answered_question'
    mail options
  end

  # Creates an email with a list of issues that have open questions
  # assigned to the user
  def question_reminder(user, issues)
    redmine_headers 'Type' => "Question"
    set_language_if_valid user.language
    @issues = issues
    @issues_url = url_for(:controller => 'questions', :action => 'my_issue_filter')
    mail to: user.mail,
      subject: l(:question_reminder_subject, :count => issues.size)
  end

  # Send email reminders to users who have open questions.
  def self.question_reminders

    open_questions_by_assignee = Question.opened.all(:order => 'id desc').group_by(&:assigned_to)

    open_questions_by_assignee.each do |assignee, questions|
      if assignee.present?
        issues = questions.collect {|q| q.issue.visible?(assignee) ? q.issue : nil }.compact.uniq
        question_reminder(assignee, issues).deliver if issues.any?
      end
    end
  end
end
