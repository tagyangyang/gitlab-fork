require 'spec_helper'

describe PreferencesHelper do
  describe 'dashboard_choices' do
    it 'raises an exception when defined choices may be missing' do
      expect(User).to receive(:dashboards).and_return(foo: 'foo')
      expect { helper.dashboard_choices }.to raise_error(RuntimeError)
    end

    it 'raises an exception when defined choices may be using the wrong key' do
      dashboards = User.dashboards.dup
      dashboards[:projects_changed] = dashboards.delete :projects
      expect(User).to receive(:dashboards).and_return(dashboards)
      expect { helper.dashboard_choices }.to raise_error(KeyError)
    end

    it 'provides better option descriptions' do
      expect(helper.dashboard_choices).to match_array [
        ['Your Projects (default)', 'projects'],
        ['Starred Projects',        'stars'],
        ["Your Projects' Activity", 'project_activity'],
        ["Starred Projects' Activity", 'starred_project_activity'],
        ["Your Groups", 'groups'],
        ["Your Todos", 'todos']
      ]
    end
  end

  describe 'user_color_scheme' do
    context 'with a user' do
      it "returns user's scheme's css_class" do
        allow(helper).to receive(:current_user).
          and_return(double(color_scheme_id: 3))

        expect(helper.user_color_scheme).to eq 'solarized-light'
      end

      it 'returns the default when id is invalid' do
        allow(helper).to receive(:current_user).
          and_return(double(color_scheme_id: Gitlab::ColorSchemes.count + 5))
      end
    end

    context 'without a user' do
      it 'returns the default theme' do
        stub_user

        expect(helper.user_color_scheme).
          to eq Gitlab::ColorSchemes.default.css_class
      end
    end
  end

  def stub_user(messages = {})
    if messages.empty?
      allow(helper).to receive(:current_user).and_return(nil)
    else
      allow(helper).to receive(:current_user).
        and_return(double('user', messages))
    end
  end

  describe '#default_project_view' do
    context 'user not signed in' do
      before do
        helper.instance_variable_set(:@project, project)
        stub_user
      end

      context 'when repository is empty' do
        let(:project) { create(:project_empty_repo, :public) }

        it 'returns activity if user has repository access' do
          allow(helper).to receive(:can?).with(nil, :download_code, project).and_return(true)

          expect(helper.default_project_view).to eq('activity')
        end

        it 'returns activity if user does not have repository access' do
          allow(helper).to receive(:can?).with(nil, :download_code, project).and_return(false)

          expect(helper.default_project_view).to eq('activity')
        end
      end

      context 'when repository is not empty' do
        let(:project) { create(:project, :public, :repository) }

        it 'returns files and readme if user has repository access' do
          allow(helper).to receive(:can?).with(nil, :download_code, project).and_return(true)

          expect(helper.default_project_view).to eq('files')
        end

        it 'returns activity if user does not have repository access' do
          allow(helper).to receive(:can?).with(nil, :download_code, project).and_return(false)

          expect(helper.default_project_view).to eq('activity')
        end
      end
    end
  end
end
