module Gitlab
  module ImportExport
    class Importer
      def initialize(project)
        @archive_file = project.import_source
        @current_user = project.creator
        @project = project
        @shared = Gitlab::ImportExport::Shared.new(relative_path: path_with_namespace)
      end

      def execute
        if import_file && check_version! && [repo_restorer, wiki_restorer, project_tree, avatar_restorer, uploads_restorer].all?(&:restore)
          project_tree.restored_project
        else
          raise Projects::ImportService::Error.new(@shared.errors.join(', '))
        end

        remove_import_file
      end

      private

      def import_file
        Gitlab::ImportExport::FileImporter.import(archive_file: @archive_file,
                                                  shared: @shared)
      end

      def check_version!
        Gitlab::ImportExport::VersionChecker.check!(shared: @shared)
      end

      def project_tree
        @project_tree ||= Gitlab::ImportExport::ProjectTreeRestorer.new(user: @current_user,
                                                                        shared: @shared,
                                                                        project: @project)
      end

      def avatar_restorer
        Gitlab::ImportExport::AvatarRestorer.new(project: project_tree.restored_project, shared: @shared)
      end

      def repo_restorer
        Gitlab::ImportExport::RepoRestorer.new(path_to_bundle: repo_path,
                                               shared: @shared,
                                               project: project_tree.restored_project)
      end

      def wiki_restorer
        Gitlab::ImportExport::RepoRestorer.new(path_to_bundle: wiki_repo_path,
                                               shared: @shared,
                                               project: ProjectWiki.new(project_tree.restored_project))
      end

      def uploads_restorer
        Gitlab::ImportExport::UploadsRestorer.new(project: project_tree.restored_project, shared: @shared)
      end

      def path_with_namespace
        File.join(@project.namespace.full_path, @project.path)
      end

      def repo_path
        File.join(@shared.export_path, 'project.bundle')
      end

      def wiki_repo_path
        File.join(@shared.export_path, 'project.wiki.bundle')
      end

      def remove_import_file
        FileUtils.rm_rf(@archive_file)
      end
    end
  end
end
