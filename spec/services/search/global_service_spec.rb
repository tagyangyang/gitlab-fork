require 'spec_helper'

describe Search::GlobalService, services: true do
  let(:user) { create(:user) }
  let(:internal_user) { create(:user) }

  let!(:found_project)    { create(:empty_project, :private, name: 'searchable_project') }
  let!(:unfound_project)  { create(:empty_project, :private, name: 'unfound_project') }
  let!(:internal_project) { create(:empty_project, :internal, name: 'searchable_internal_project') }
  let!(:public_project)   { create(:empty_project, :public, name: 'searchable_public_project') }

  before do
    found_project.add_master(user)
  end

  describe '#execute' do
    context 'unauthenticated' do
      it 'returns public projects only' do
        results = Search::GlobalService.new(nil, search: "searchable").execute

        expect(results.objects('projects')).to match_array [public_project]
      end
    end

    context 'authenticated' do
      it 'returns public, internal and private projects' do
        results = Search::GlobalService.new(user, search: "searchable").execute

        expect(results.objects('projects')).to match_array [public_project, found_project, internal_project]
      end

      it 'returns only public & internal projects' do
        results = Search::GlobalService.new(internal_user, search: "searchable").execute

        expect(results.objects('projects')).to match_array [internal_project, public_project]
      end

      it 'namespace name is searchable' do
        results = Search::GlobalService.new(user, search: found_project.namespace.path).execute

        expect(results.objects('projects')).to match_array [found_project]
      end

      context 'nested group' do
        let!(:nested_group) { create(:group, :nested) }
        let!(:project) { create(:empty_project, namespace: nested_group) }

        before do
          project.add_master(user)
        end

        it 'returns result from nested group' do
          results = Search::GlobalService.new(user, search: project.path).execute

          expect(results.objects('projects')).to match_array [project]
        end

        it 'returns result from descendants when search inside group' do
          results = Search::GlobalService.new(user, search: project.path, group_id: nested_group.parent).execute

          expect(results.objects('projects')).to match_array [project]
        end
      end
    end
  end
end
