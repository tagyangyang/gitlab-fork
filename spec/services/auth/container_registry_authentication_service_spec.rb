require 'spec_helper'

describe Auth::ContainerRegistryAuthenticationService, services: true do
  let(:current_project) { nil }
  let(:current_user) { nil }
  let(:current_params) { {} }
  let(:rsa_key) { OpenSSL::PKey::RSA.generate(512) }
  let(:payload) { JWT.decode(subject[:token], rsa_key).first }

  let(:authentication_abilities) do
    [:read_container_image, :create_container_image]
  end

  subject do
    described_class.new(current_project, current_user, current_params)
      .execute(authentication_abilities: authentication_abilities)
  end

  before do
    allow(Gitlab.config.registry).to receive_messages(enabled: true, issuer: 'rspec', key: nil)
    allow_any_instance_of(JSONWebToken::RSAToken).to receive(:key).and_return(rsa_key)
  end

  shared_examples 'a valid token' do
    it { is_expected.to include(:token) }
    it { expect(payload).to include('access') }

    context 'a expirable' do
      let(:expires_at) { Time.at(payload['exp']) }
      let(:expire_delay) { 10 }

      context 'for default configuration' do
        it { expect(expires_at).not_to be_within(2.seconds).of(Time.now + expire_delay.minutes) }
      end

      context 'for changed configuration' do
        before { stub_application_setting(container_registry_token_expire_delay: expire_delay) }

        it { expect(expires_at).to be_within(2.seconds).of(Time.now + expire_delay.minutes) }
      end
    end
  end

  shared_examples 'an accessible' do
    let(:access) do
      [{ 'type' => 'repository',
         'name' => project.path_with_namespace,
         'actions' => actions }]
    end

    it_behaves_like 'a valid token'
    it { expect(payload).to include('access' => access) }
  end

  shared_examples 'an inaccessible' do
    it_behaves_like 'a valid token'
    it { expect(payload).to include('access' => []) }
  end

  shared_examples 'a pullable' do
    it_behaves_like 'an accessible' do
      let(:actions) { ['pull'] }
    end
  end

  shared_examples 'a pushable' do
    it_behaves_like 'an accessible' do
      let(:actions) { ['push'] }
    end
  end

  shared_examples 'a pullable and pushable' do
    it_behaves_like 'an accessible' do
      let(:actions) { %w(pull push) }
    end
  end

  shared_examples 'a forbidden' do
    it { is_expected.to include(http_status: 403) }
    it { is_expected.not_to include(:token) }
  end

  shared_examples 'container repository factory' do
    it 'creates a new container repository resource' do
      expect { subject }
        .to change { project.container_repositories.count }.by(1)
    end
  end

  shared_examples 'not a container repository factory' do
    it 'does not create a new container repository resource' do
      expect { subject }.not_to change { ContainerRepository.count }
    end
  end

  describe '#full_access_token' do
    let(:project) { create(:empty_project) }
    let(:token) { described_class.full_access_token(project.path_with_namespace) }

    subject { { token: token } }

    it_behaves_like 'an accessible' do
      let(:actions) { ['*'] }
    end

    it_behaves_like 'not a container repository factory'
  end

  context 'user authorization' do
    let(:current_user) { create(:user) }

    context 'for private project' do
      let(:project) { create(:empty_project) }

      context 'allow to use scope-less authentication' do
        it_behaves_like 'a valid token'
      end

      context 'allow developer to push images' do
        before { project.team << [current_user, :developer] }

        let(:current_params) do
          { scope: "repository:#{project.path_with_namespace}:push" }
        end

        it_behaves_like 'a pushable'
        it_behaves_like 'container repository factory'
      end

      context 'allow reporter to pull images' do
        before { project.team << [current_user, :reporter] }

        context 'when pulling from root level repository' do
          let(:current_params) do
            { scope: "repository:#{project.path_with_namespace}:pull" }
          end

          it_behaves_like 'a pullable'
          it_behaves_like 'not a container repository factory'
        end
      end

      context 'return a least of privileges' do
        before { project.team << [current_user, :reporter] }

        let(:current_params) do
          { scope: "repository:#{project.path_with_namespace}:push,pull" }
        end

        it_behaves_like 'a pullable'
        it_behaves_like 'not a container repository factory'
      end

      context 'disallow guest to pull or push images' do
        before { project.team << [current_user, :guest] }

        let(:current_params) do
          { scope: "repository:#{project.path_with_namespace}:pull,push" }
        end

        it_behaves_like 'an inaccessible'
        it_behaves_like 'not a container repository factory'
      end
    end

    context 'for public project' do
      let(:project) { create(:empty_project, :public) }

      context 'allow anyone to pull images' do
        let(:current_params) do
          { scope: "repository:#{project.path_with_namespace}:pull" }
        end

        it_behaves_like 'a pullable'
        it_behaves_like 'not a container repository factory'
      end

      context 'disallow anyone to push images' do
        let(:current_params) do
          { scope: "repository:#{project.path_with_namespace}:push" }
        end

        it_behaves_like 'an inaccessible'
        it_behaves_like 'not a container repository factory'
      end

      context 'when repository name is invalid' do
        let(:current_params) do
          { scope: 'repository:invalid:push' }
        end

        it_behaves_like 'an inaccessible'
        it_behaves_like 'not a container repository factory'
      end
    end

    context 'for internal project' do
      let(:project) { create(:empty_project, :internal) }

      context 'for internal user' do
        context 'allow anyone to pull images' do
          let(:current_params) do
            { scope: "repository:#{project.path_with_namespace}:pull" }
          end

          it_behaves_like 'a pullable'
          it_behaves_like 'not a container repository factory'
        end

        context 'disallow anyone to push images' do
          let(:current_params) do
            { scope: "repository:#{project.path_with_namespace}:push" }
          end

          it_behaves_like 'an inaccessible'
          it_behaves_like 'not a container repository factory'
        end
      end

      context 'for external user' do
        let(:current_user) { create(:user, external: true) }
        let(:current_params) do
          { scope: "repository:#{project.path_with_namespace}:pull,push" }
        end

        it_behaves_like 'an inaccessible'
        it_behaves_like 'not a container repository factory'
      end
    end
  end

  context 'build authorized as user' do
    let(:current_project) { create(:empty_project) }
    let(:current_user) { create(:user) }

    let(:authentication_abilities) do
      [:build_read_container_image, :build_create_container_image]
    end

    before do
      current_project.team << [current_user, :developer]
    end

    it_behaves_like 'a valid token'

    context 'allow to pull and push images' do
      let(:current_params) do
        { scope: "repository:#{current_project.path_with_namespace}:pull,push" }
      end

      it_behaves_like 'a pullable and pushable' do
        let(:project) { current_project }
      end

      it_behaves_like 'container repository factory' do
        let(:project) { current_project }
      end
    end

    context 'for other projects' do
      context 'when pulling' do
        let(:current_params) do
          { scope: "repository:#{project.path_with_namespace}:pull" }
        end

        context 'allow for public' do
          let(:project) { create(:empty_project, :public) }

          it_behaves_like 'a pullable'
          it_behaves_like 'not a container repository factory'
        end

        shared_examples 'pullable for being team member' do
          context 'when you are not member' do
            it_behaves_like 'an inaccessible'
            it_behaves_like 'not a container repository factory'
          end

          context 'when you are member' do
            before do
              project.team << [current_user, :developer]
            end

            it_behaves_like 'a pullable'
            it_behaves_like 'not a container repository factory'
          end

          context 'when you are owner' do
            let(:project) { create(:empty_project, namespace: current_user.namespace) }

            it_behaves_like 'a pullable'
            it_behaves_like 'not a container repository factory'
          end
        end

        context 'for private' do
          let(:project) { create(:empty_project, :private) }

          it_behaves_like 'pullable for being team member'

          context 'when you are admin' do
            let(:current_user) { create(:admin) }

            context 'when you are not member' do
              it_behaves_like 'an inaccessible'
              it_behaves_like 'not a container repository factory'
            end

            context 'when you are member' do
              before do
                project.team << [current_user, :developer]
              end

              it_behaves_like 'a pullable'
              it_behaves_like 'not a container repository factory'
            end

            context 'when you are owner' do
              let(:project) { create(:empty_project, namespace: current_user.namespace) }

              it_behaves_like 'a pullable'
              it_behaves_like 'not a container repository factory'
            end
          end
        end
      end

      context 'when pushing' do
        let(:current_params) do
          { scope: "repository:#{project.path_with_namespace}:push" }
        end

        context 'disallow for all' do
          context 'when you are member' do
            let(:project) { create(:empty_project, :public) }

            before do
              project.team << [current_user, :developer]
            end

            it_behaves_like 'an inaccessible'
            it_behaves_like 'not a container repository factory'
          end

          context 'when you are owner' do
            let(:project) { create(:empty_project, :public, namespace: current_user.namespace) }

            it_behaves_like 'an inaccessible'
            it_behaves_like 'not a container repository factory'
          end
        end
      end
    end

    context 'for project without container registry' do
      let(:project) { create(:empty_project, :public, container_registry_enabled: false) }

      before { project.update(container_registry_enabled: false) }

      context 'disallow when pulling' do
        let(:current_params) do
          { scope: "repository:#{project.path_with_namespace}:pull" }
        end

        it_behaves_like 'an inaccessible'
        it_behaves_like 'not a container repository factory'
      end
    end
  end

  context 'unauthorized' do
    context 'disallow to use scope-less authentication' do
      it_behaves_like 'a forbidden'
      it_behaves_like 'not a container repository factory'
    end

    context 'for invalid scope' do
      let(:current_params) do
        { scope: 'invalid:aa:bb' }
      end

      it_behaves_like 'a forbidden'
      it_behaves_like 'not a container repository factory'
    end

    context 'for private project' do
      let(:project) { create(:empty_project, :private) }

      let(:current_params) do
        { scope: "repository:#{project.path_with_namespace}:pull" }
      end

      it_behaves_like 'a forbidden'
    end

    context 'for public project' do
      let(:project) { create(:empty_project, :public) }

      context 'when pulling and pushing' do
        let(:current_params) do
          { scope: "repository:#{project.path_with_namespace}:pull,push" }
        end

        it_behaves_like 'a pullable'
        it_behaves_like 'not a container repository factory'
      end

      context 'when pushing' do
        let(:current_params) do
          { scope: "repository:#{project.path_with_namespace}:push" }
        end

        it_behaves_like 'a forbidden'
        it_behaves_like 'not a container repository factory'
      end
    end
  end
end
