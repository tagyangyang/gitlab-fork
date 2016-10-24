require_relative '../support/repo_helpers'

include ActionDispatch::TestProcess

FactoryGirl.define do
  factory :custom_emoji do
    project
    name "tanuki"
    emoji { fixture_file_upload(Rails.root + "spec/fixtures/dk.png", "`/png") }
  end
end
