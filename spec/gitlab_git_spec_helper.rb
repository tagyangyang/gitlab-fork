require "spec_helper"

require 'simplecov'
SimpleCov.start

require 'pry'
require 'rspec/its'

RSpec::Matchers.define :be_valid_commit do
  match do |actual|
    actual &&
      actual.id == SeedRepo::Commit::ID &&
      actual.message == SeedRepo::Commit::MESSAGE &&
      actual.author_name == SeedRepo::Commit::AUTHOR_FULL_NAME
  end
end

GITLAB_GIT_REPOS_PATH = Rails.root.join('tmp', 'gitlab_git_tests').to_s
TEST_REPO_PATH = File.join(GITLAB_GIT_REPOS_PATH, 'gitlab-git-test.git')
TEST_NORMAL_REPO_PATH = File.join(GITLAB_GIT_REPOS_PATH, "not-bare-repo.git")
TEST_MUTABLE_REPO_PATH = File.join(GITLAB_GIT_REPOS_PATH, "mutable-repo.git")
TEST_BROKEN_REPO_PATH = File.join(GITLAB_GIT_REPOS_PATH, "broken-repo.git")

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.order = 'random'
  config.include SeedHelper
  config.before(:all) { ensure_seeds }
end
