module QuestionPlugin
  module Patches

    module QueryPatch
      def self.included(base) # :nodoc:
        base.extend(ClassMethods)

        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable # Send unloadable so it will not be unloaded in development
          base.add_available_column(QueryColumn.new(:formatted_questions))

          alias_method_chain :initialize_available_filters, :questions
          alias_method_chain :sql_for_field, :questions
          alias_method_chain :joins_for_order_statement, :questions
          alias_method_chain :issue_count, :questions
        end

      end

      module ClassMethods
      end

      module InstanceMethods

        def joins_for_order_statement_with_questions(order_options)
          (joins_for_order_statement_without_questions(order_options) || '') +
            " left outer join questions on questions.issue_id = issues.id"
        end

        def sql_for_field_with_questions(field, operator, value, db_table, db_field, is_custom_filter=false)

          if field == "question_assigned_to_id" || field == "question_asked_by_id"
            v = values_for(field).clone

            db_table = Question.table_name
            if field == "question_assigned_to_id"
              db_field = 'assigned_to_id'
            else
              db_field = 'author_id'
            end

            # "me" value subsitution
            v.push(User.current.logged? ? User.current.id.to_s : "0") if v.delete("me")

            case operator
            when "="
              sql = "#{db_table}.#{db_field} IN (" + v.collect{|val| "'#{connection.quote_string(val)}'"}.join(",") + ") AND #{db_table}.opened = true"
            when "!"
              sql = "(#{db_table}.#{db_field} IS NULL OR #{db_table}.#{db_field} NOT IN (" + v.collect{|val| "'#{connection.quote_string(val)}'"}.join(",") + ")) AND #{db_table}.opened = true"
            end

            return sql

          else
            return sql_for_field_without_questions(field, operator, value, db_table, db_field, is_custom_filter)
          end
        end

        def issue_count_with_questions
          Issue.visible.count(:include => [:status, :project, :questions], :conditions => statement)
        end

        # Wrapper around the +initialize_available_filters+
        # to add a new Question filter
        def initialize_available_filters_with_questions
          initialize_available_filters_without_questions

          user_values = []
          user_values << ["<< #{l(:label_me)} >>", "me"] if User.current.logged?
          if project
            user_values += project.users.sort.collect{|s| [s.name, s.id.to_s] }
          else
            user_values += User.current.projects.collect(&:users).flatten.uniq.sort.collect{|s| [s.name, s.id.to_s] }
          end

          add_available_filter "question_assigned_to_id",
            :type => :list, :order => 14, :values => user_values
          add_available_filter "question_asked_by_id",
            :type => :list, :order => 14, :values => user_values

        end


      end
    end

  end
end
