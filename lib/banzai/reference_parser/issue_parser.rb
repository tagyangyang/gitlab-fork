module Banzai
  module ReferenceParser
    class IssueParser < BaseParser
      self.reference_type = :issue

      def nodes_visible_to_user(user, nodes)
        # It is not possible to check access rights for external issue trackers
        return nodes if project && project.external_issue_tracker

        issues = issues_for_nodes(nodes)

        readable_issues = Ability.
          issues_readable_by_user(issues.values, user).to_set

        nodes.select do |node|
          readable_issues.include?(issue_for_node(issues, node))
        end
      end

      def referenced_by(nodes)
        issues = issues_for_nodes(nodes)

        nodes.map { |node| issue_for_node(issues, node) }.uniq
      end

      def issues_for_nodes(nodes)
        @issues_for_nodes ||= begin
          issues = raw_issues_for_nodes(nodes)
          users = raw_issues_users(issues)
          projects = raw_issues_projects(issues)

          issues.each do |_id, issue|
            preload_from_cache(users, issue, :author)
            preload_from_cache(users, issue, :assignee)
            preload_from_cache(projects, issue, :project)
          end if RequestStore.active?

          preload(issues.values, :project,
            # These associations are primarily used for checking permissions.
            # Eager loading these ensures we don't end up running dozens of
            # queries in this process.
            project: [
                       { namespace: :owner },
                       { group: [:owners, :group_members] },
                       :invited_groups,
                       :project_members
                     ]
          )
          preload(issues.values, :author)
          preload(issues.values, :assignee)

          issues
        end
      end

      private

      # Set as loaded an association retrieving the object for the existing cache
      def preload_from_cache(records_cache, record, association_name)
        association = record.association(association_name)
        loaded_record = records_cache.detect { |cached_record| cached_record.id == record[association.reflection.foreign_key] }
        association.target = loaded_record if loaded_record
      end

      # Load specified association_name only on the records that have not that association loaded.
      # When preloading AR check the first record to decide if the association has to be loaded or not so we need
      # to provide records with that association not loaded only.
      # As the original record came from the cache and we're going to use the same instance nothing has to be
      # stored in the cache from this method.
      def preload(records, association_name, associations = nil)
        records_not_loaded = records.select { |record| !record.association(association_name).loaded? }
        ActiveRecord::Associations::Preloader.new.preload(records_not_loaded, associations || association_name)
      end

      def raw_issues_users(issues)
        # Cache currrent_user
        collection_cache[collection_cache_key(User.all)][current_user.id] = current_user if current_user
        user_ids = issues.flat_map { |issue_id, issue| [issue.author_id, issue.assignee_id] }.compact.uniq
        collection_objects_for_ids(User.all, user_ids).to_a
      end

      def raw_issues_projects(issues)
        # Cache current project
        collection_cache[collection_cache_key(Project.all)][project.id] = project if project
        project_ids = issues.map { |issue_id, issue| issue.project_id }.compact.uniq
        collection_objects_for_ids(Project.all, project_ids).to_a
      end

      def raw_issues_for_nodes(nodes)
        grouped_objects_for_nodes(
          nodes,
          Issue.all,
          self.class.data_attribute
        )
      end

      def issue_for_node(issues, node)
        issues[node.attr(self.class.data_attribute).to_i]
      end
    end
  end
end
