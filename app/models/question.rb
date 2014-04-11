class Question < ActiveRecord::Base
  unloadable
  TruncateTo = 120

  belongs_to :assigned_to, :class_name => "User", :foreign_key => "assigned_to_id"
  belongs_to :author, :class_name => "User", :foreign_key => "author_id"
  belongs_to :issue
  belongs_to :journal

  validates_presence_of :author
  validates_presence_of :issue
  validates_presence_of :journal

  after_create :notify_receiver

  scope :opened, lambda { where opened: true }
  scope :for_user, lambda {|user| where assigned_to_id: user.id }
  scope :for_anyone, lambda{ where assigned_to_id: nil }
  scope :by_user, lambda {|user| where author_id: user.id }

  delegate :notes, :to => :journal, :allow_nil => true

  def for_anyone?
    self.assigned_to.nil?
  end

  def close!(closing_journal = nil)
    if opened
      self.opened = false
      if save && closing_journal
        QuestionMailer.answered_question(self, closing_journal).deliver
      end
    end
  end

  def self.count_open_questions(user = User.current, project = nil)
    open = opened.for_user(user)
    if project
      open = open.joins(issue: [:project]).where(issues: {project_id: project.id})
    end
    open.count
  end

#  def self.count_of_open_for_user(user)
#    opened.for_user(user).count
#  end
#
#  def self.count_of_open_for_user_on_project(user, project)
#    opened.for_user(user)
#    Question.count(:conditions => ["#{Question.table_name}.assigned_to_id = ? AND #{Project.table_name}.id = ? AND #{Question.table_name}.opened = ?",
#                                   user.id,
#                                   project.id,
#                                   true],
#                   :include => [:issue => [:project]])
#  end

  private

  def notify_receiver
    QuestionMailer.asked_question(journal).deliver
  end

end
