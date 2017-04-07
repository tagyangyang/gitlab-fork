require 'spec_helper'

describe ProjectsHelper do
  describe "#project_status_css_class" do
    it "returns appropriate class" do
      expect(project_status_css_class("started")).to eq("active")
      expect(project_status_css_class("failed")).to eq("danger")
      expect(project_status_css_class("finished")).to eq("success")
    end
  end

  describe "can_change_visibility_level?" do
    let(:project) { create(:project, :repository) }
    let(:user) { create(:project_member, :reporter, user: create(:user), project: project).user }
    let(:fork_project) { Projects::ForkService.new(project, user).execute }

    it "returns false if there are no appropriate permissions" do
      allow(helper).to receive(:can?) { false }

      expect(helper.can_change_visibility_level?(project, user)).to be_falsey
    end

    it "returns true if there are permissions and it is not fork" do
      allow(helper).to receive(:can?) { true }

      expect(helper.can_change_visibility_level?(project, user)).to be_truthy
    end

    context "forks" do
      it "returns false if there are permissions and origin project is PRIVATE" do
        allow(helper).to receive(:can?) { true }

        project.update visibility_level:  Gitlab::VisibilityLevel::PRIVATE

        expect(helper.can_change_visibility_level?(fork_project, user)).to be_falsey
      end

      it "returns true if there are permissions and origin project is INTERNAL" do
        allow(helper).to receive(:can?) { true }

        project.update visibility_level:  Gitlab::VisibilityLevel::INTERNAL

        expect(helper.can_change_visibility_level?(fork_project, user)).to be_truthy
      end
    end
  end

  describe "readme_cache_key" do
    let(:project) { create(:project) }

    before do
      helper.instance_variable_set(:@project, project)
    end

    it "returns a valid cach key" do
      expect(helper.send(:readme_cache_key)).to eq("#{project.path_with_namespace}-#{project.commit.id}-readme")
    end

    it "returns a valid cache key if HEAD does not exist" do
      allow(project).to receive(:commit) { nil }

      expect(helper.send(:readme_cache_key)).to eq("#{project.path_with_namespace}-nil-readme")
    end
  end

  describe "#project_list_cache_key" do
    let(:project) { create(:project) }

    it "includes the namespace" do
      expect(helper.project_list_cache_key(project)).to include(project.namespace.cache_key)
    end

    it "includes the project" do
      expect(helper.project_list_cache_key(project)).to include(project.cache_key)
    end

    it "includes the controller name" do
      expect(helper.controller).to receive(:controller_name).and_return("testcontroller")

      expect(helper.project_list_cache_key(project)).to include("testcontroller")
    end

    it "includes the controller action" do
      expect(helper.controller).to receive(:action_name).and_return("testaction")

      expect(helper.project_list_cache_key(project)).to include("testaction")
    end

    it "includes the application settings" do
      settings = Gitlab::CurrentSettings.current_application_settings

      expect(helper.project_list_cache_key(project)).to include(settings.cache_key)
    end

    it "includes a version" do
      expect(helper.project_list_cache_key(project)).to include("v2.3")
    end

    it "includes the pipeline status when there is a status" do
      create(:ci_pipeline, :success, project: project, sha: project.commit.sha)

      expect(helper.project_list_cache_key(project)).to include("pipeline-status/#{project.commit.sha}-success")
    end
  end

  describe 'link_to_member' do
    let(:group)   { create(:group) }
    let(:project) { create(:empty_project, group: group) }
    let(:user)    { create(:user) }

    describe 'using the default options' do
      it 'returns an HTML link to the user' do
        link = helper.link_to_member(project, user)

        expect(link).to match(%r{/#{user.username}})
      end
    end
  end

  describe 'default_clone_protocol' do
    context 'when user is not logged in and gitlab protocol is HTTP' do
      it 'returns HTTP' do
        allow(helper).to receive(:current_user).and_return(nil)

        expect(helper.send(:default_clone_protocol)).to eq('http')
      end
    end

    context 'when user is not logged in and gitlab protocol is HTTPS' do
      it 'returns HTTPS' do
        stub_config_setting(protocol: 'https')
        allow(helper).to receive(:current_user).and_return(nil)

        expect(helper.send(:default_clone_protocol)).to eq('https')
      end
    end
  end

  describe '#license_short_name' do
    let(:project) { create(:empty_project) }

    context 'when project.repository has a license_key' do
      it 'returns the nickname of the license if present' do
        allow(project.repository).to receive(:license_key).and_return('agpl-3.0')

        expect(helper.license_short_name(project)).to eq('GNU AGPLv3')
      end

      it 'returns the name of the license if nickname is not present' do
        allow(project.repository).to receive(:license_key).and_return('mit')

        expect(helper.license_short_name(project)).to eq('MIT License')
      end
    end

    context 'when project.repository has no license_key but a license_blob' do
      it 'returns LICENSE' do
        allow(project.repository).to receive(:license_key).and_return(nil)

        expect(helper.license_short_name(project)).to eq('LICENSE')
      end
    end
  end

  describe '#sanitized_import_error' do
    let(:project) { create(:project) }

    before do
      allow(project).to receive(:repository_storage_path).and_return('/base/repo/path')
      allow(Settings.shared).to receive(:[]).with('path').and_return('/base/repo/export/path')
    end

    it 'removes the repo path' do
      repo = '/base/repo/path/namespace/test.git'
      import_error = "Could not clone #{repo}\n"

      expect(sanitize_repo_path(project, import_error)).to eq('Could not clone [REPOS PATH]/namespace/test.git')
    end

    it 'removes the temporary repo path used for uploads/exports' do
      repo = '/base/repo/export/path/tmp/project_exports/uploads/test.tar.gz'
      import_error = "Unable to decompress #{repo}\n"

      expect(sanitize_repo_path(project, import_error)).to eq('Unable to decompress [REPO EXPORT PATH]/uploads/test.tar.gz')
    end
  end

  describe '#last_push_event' do
    let(:user) { double(:user, fork_of: nil) }
    let(:project) { double(:project, id: 1) }

    before do
      allow(helper).to receive(:current_user).and_return(user)
      helper.instance_variable_set(:@project, project)
    end

    context 'when there is no current_user' do
      let(:user) { nil }

      it 'returns nil' do
        expect(helper.last_push_event).to eq(nil)
      end
    end

    it 'returns recent push on the current project' do
      event = double(:event)
      expect(user).to receive(:recent_push).with([project.id]).and_return(event)

      expect(helper.last_push_event).to eq(event)
    end

    context 'when current user has a fork of the current project' do
      let(:fork) { double(:fork, id: 2) }

      it 'returns recent push considering fork events' do
        expect(user).to receive(:fork_of).with(project).and_return(fork)

        event_on_fork = double(:event)
        expect(user).to receive(:recent_push).with([project.id, fork.id]).and_return(event_on_fork)

        expect(helper.last_push_event).to eq(event_on_fork)
      end
    end
  end

  describe "#project_feature_access_select" do
    let(:project) { create(:empty_project, :public) }
    let(:user)    { create(:user) }

    context "when project is internal or public" do
      it "shows all options" do
        helper.instance_variable_set(:@project, project)
        result = helper.project_feature_access_select(:issues_access_level)
        expect(result).to include("Disabled")
        expect(result).to include("Only team members")
        expect(result).to include("Everyone with access")
      end
    end

    context "when project is private" do
      before { project.update_attributes(visibility_level: Gitlab::VisibilityLevel::PRIVATE) }

      it "shows only allowed options" do
        helper.instance_variable_set(:@project, project)
        result = helper.project_feature_access_select(:issues_access_level)
        expect(result).to include("Disabled")
        expect(result).to include("Only team members")
        expect(result).not_to include("Everyone with access")
      end
    end

    context "when project moves from public to private" do
      before do
        project.update_attributes(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      end

      it "shows the highest allowed level selected" do
        helper.instance_variable_set(:@project, project)
        result = helper.project_feature_access_select(:issues_access_level)

        expect(result).to include("Disabled")
        expect(result).to include("Only team members")
        expect(result).not_to include("Everyone with access")
        expect(result).to have_selector('option[selected]', text: "Only team members")
      end
    end
  end
end
