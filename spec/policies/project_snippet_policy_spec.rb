require 'spec_helper'

describe ProjectSnippetPolicy, models: true do
  let(:current_user) { create(:user) }

  let(:author_permissions) do
    [
      :update_project_snippet,
      :admin_project_snippet
    ]
  end

  def expect_allowed(*permissions)
    permissions.each { |p| is_expected.to be_allowed(p) }
  end

  def expect_disallowed(*permissions)
    permissions.each { |p| is_expected.not_to be_allowed(p) }
  end

  subject { described_class.new(current_user, project_snippet) }

  context 'public snippet' do
    let(:project_snippet) { create(:project_snippet, :public) }

    context 'no user' do
      let(:current_user) { nil }

      it do
        expect_allowed(:read_project_snippet)
        expect_disallowed(*author_permissions)
      end
    end

    context 'regular user' do
      it do
        expect_allowed(:read_project_snippet)
        expect_disallowed(*author_permissions)
      end
    end
  end

  context 'internal snippet' do
    let(:project_snippet) { create(:project_snippet, :internal) }

    context 'no user' do
      let(:current_user) { nil }

      it do
        expect_disallowed(:read_project_snippet)
        expect_disallowed(*author_permissions)
      end
    end

    context 'regular user' do
      it do
        expect_allowed(:read_project_snippet)
        expect_disallowed(*author_permissions)
      end
    end
  end

  context 'private snippet' do
    let(:project_snippet) { create(:project_snippet, :private) }

    context 'no user' do
      let(:current_user) { nil }

      it do
        expect_disallowed(:read_project_snippet)
        expect_disallowed(*author_permissions)
      end
    end

    context 'regular user' do
      it do
        expect_disallowed(:read_project_snippet)
        expect_disallowed(*author_permissions)
      end
    end

    context 'snippet author' do
      let(:project_snippet) { create(:project_snippet, :private, author: current_user) }

      it do
        expect_allowed(:read_project_snippet)
        expect_allowed(*author_permissions)
      end
    end

    context 'project team member' do
      before { project_snippet.project.team << [current_user, :developer] }

      it do
        expect_allowed(:read_project_snippet)
        expect_disallowed(*author_permissions)
      end
    end

    context 'admin user' do
      let(:current_user) { create(:admin) }

      it do
        expect_allowed(:read_project_snippet)
        expect_allowed(*author_permissions)
      end
    end
  end
end
