class QuestionsController < ApplicationController
  unloadable
  before_filter :find_project, only: :autocomplete_for_user_login
  layout 'base'

  # Create a query in the session and redirects to the issue list with that query
  def my_issue_filter
    new_filter_for_questions_assigned_to('me')
    redirect_to :controller => 'issues', :action => 'index', :project_id => params[:project]
  end

  def user_issue_filter
    new_filter_for_questions_assigned_to(params[:user_id])
    redirect_to :controller => 'issues', :action => 'index', :project_id => params[:project]
  end

  def autocomplete_for_user_login
    @users = User.active.sorted.like(params[:term]).limit(100).all
    if @project && params[:issue_id] && User.current.allowed_to?(:view_issues, @project)

      issue = @project.issues.find params[:issue_id]
      @users.unshift issue.assigned_to if issue.assigned_to
      @users.unshift issue.author if issue.author
      @users.reject!{|u| u == User.current}.uniq!
    end

    render :layout => false
  end

  private

  def new_filter_for_questions_assigned_to(user_id)
    @project = Project.find(params[:project]) unless params[:project].nil?

    @query = IssueQuery.new(:name => "_",
                           :filters => {'status_id' => {:operator => '*', :values => [""]}}
                       )
    @query.project = @project unless params[:project].nil?
    @query.add_filter("question_assigned_to_id", '=',[user_id])

    session[:query] = {:project_id => @query.project_id, :filters => @query.filters}
  end

  def find_project
    @project = Project.find params[:project_id] if params[:project_id]
  end

end
