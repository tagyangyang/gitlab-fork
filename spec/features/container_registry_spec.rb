require 'spec_helper'

describe "Container Registry" do
  let(:user) { create(:user) }
  let(:project) { create(:empty_project) }

  let(:container_repository) do
    create(:container_repository, name: 'my/image')
  end

  before do
    login_as(user)
    project.add_developer(user)
    stub_container_registry_config(enabled: true)
    stub_container_registry_tags(repository: :any, tags: [])
  end

  context 'when there are no image repositories' do
    scenario 'user visits container registry main page' do
      visit_container_registry

      expect(page).to have_content 'No container image repositories'
    end
  end

  context 'when there are image repositories' do
    before do
      stub_container_registry_tags(repository: %r{my/image}, tags: %w[latest])
      project.container_repositories << container_repository
    end

    scenario 'user wants to see multi-level container repository' do
      visit_container_registry

      expect(page).to have_content('my/image')
    end

    scenario 'user removes entire container repository' do
      visit_container_registry

      expect_any_instance_of(ContainerRepository)
        .to receive(:delete_tags!).and_return(true)

      click_on 'Remove repository'
    end

    scenario 'user removes a specific tag from container repository' do
      visit_container_registry

      expect_any_instance_of(ContainerRegistry::Tag)
        .to receive(:delete).and_return(true)

      click_on 'Remove tag'
    end
  end

  def visit_container_registry
    visit namespace_project_container_registry_index_path(
      project.namespace, project)
  end
end
