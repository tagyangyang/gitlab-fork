FactoryGirl.define do
  factory :environment, class: Environment do
    sequence(:name) { |n| "environment#{n}" }

    project factory: :empty_project
    sequence(:external_url) { |n| "https://env#{n}.example.gitlab.com" }

    trait :with_review_app do |environment|
      project

      transient do
        ref 'master'
      end

      # At this point `review app` is an ephemeral concept related to
      # deployments being deployed for given environment. There is no
      # first-class `review app` available so we need to create set of
      # interconnected objects to simulate a review app.
      #
      after(:create) do |environment, evaluator|
        deployment = create(:deployment,
                            environment: environment,
                            project: environment.project,
                            ref: evaluator.ref,
                            sha: environment.project.commit(evaluator.ref).id)

        teardown_build = create(:ci_build, :manual,
                                name: "#{deployment.environment.name}:teardown",
                                pipeline: deployment.deployable.pipeline)

        deployment.update_column(:on_stop, teardown_build.name)
        environment.update_attribute(:deployments, [deployment])
      end
    end

    trait :non_playable do
      status 'created'
      self.when 'manual'
    end
  end
end
