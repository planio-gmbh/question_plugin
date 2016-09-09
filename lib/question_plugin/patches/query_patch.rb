module QuestionPlugin
  module Patches

    module QueryPatch
      def self.apply
        # check if thats a good idea
        IssueQuery.send :prepend, self unless IssueQuery < self
      end

      def self.prepended(base) # :nodoc:
        base.add_available_column(QueryColumn.new(:formatted_questions))

      end

        def joins_for_order_statement(order_options)
          (super(order_options) || '') +
            " left outer join questions on questions.issue_id = issues.id"
        end

        def sql_for_field(field, operator, value, db_table, db_field, is_custom_filter=false)

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
            return super(field, operator, value, db_table, db_field, is_custom_filter)
          end
        end

        def base_scope
          super.eager_load(:questions)
        end

        # Wrapper around the +initialize_available_filters+
        # to add a new Question filter
        def initialize_available_filters
          super

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
