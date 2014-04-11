
get 'questions/autocomplete_for_assignee', to: 'questions#autocomplete_for_user_login', as: 'autocomplete_for_question_assignee'
get 'questions/my_issue_filter/:project', to: 'questions#my_issue_filter'
get 'questions/user_issue_filter/:project/:user_id', to: 'questions#my_issue_filter'
