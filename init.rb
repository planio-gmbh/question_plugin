require 'question_plugin/hooks'

Rails.configuration.to_prepare do
  Issue.send(:include, QuestionPlugin::Patches::IssuePatch) unless Issue.included_modules.include? QuestionPlugin::Patches::IssuePatch

  Journal.send(:include, QuestionPlugin::Patches::JournalPatch) unless Journal.included_modules.include? QuestionPlugin::Patches::JournalPatch

  QueriesHelper.send(:include, QuestionPlugin::Patches::QueriesHelperPatch) unless QueriesHelper.included_modules.include? QuestionPlugin::Patches::QueriesHelperPatch

  IssueQuery.send(:include, QuestionPlugin::Patches::QueryPatch) unless IssueQuery.included_modules.include? QuestionPlugin::Patches::QueryPatch
end

Redmine::Plugin.register :question_plugin do
  name 'Redmine Question plugin'
  author 'Eric Davis'
  url "https://projects.littlestreamsoftware.com/projects/redmine-questions" if respond_to?(:url)
  author_url 'http://www.littlestreamsoftware.com' if respond_to?(:author_url)
  description 'This is a plugin for Redmine that will allow users to ask questions to each other in issue notes'
  version '0.4.0'

  requires_redmine :version_or_higher => '2.3.0'

end

