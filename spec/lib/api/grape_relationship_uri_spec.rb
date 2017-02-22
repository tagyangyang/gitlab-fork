require 'spec_helper'

describe API::GrapeRelationshipUri, api: true do
  describe '#build' do
    let(:request_api_version) { 'v4' }
    let(:grape_request_wrapper) do
      double(base_url: 'https://example.com',
             env: { Grape::Env::GRAPE_ROUTING_ARGS => { version: request_api_version }})
    end

    subject { described_class.build(related_entities, grape_request_wrapper) }

    context 'when related resource URI does not have params' do
      let(:related_entities) do
        [
          { name: :hooks_url, entity: API::Entities::Hook },
          { name: :issues_url, entity: API::Entities::Issue }
        ]
      end

      it 'return built URLs with resource names' do
        urls_hash = {
          issues_url: 'https://example.com/api/v4/issues',
          hooks_url: 'https://example.com/api/v4/hooks'
        }

        is_expected.to eql(urls_hash)
      end
    end

    context 'when related resource URI does have params' do
      let(:related_entities) do
        [
          { name: :merge_request_url, entity: API::Entities::MergeRequest, params: { id: 1, merge_request_id: 2 } },
          { name: :issues_url, entity: API::Entities::Issue, params: { id: 1 } }
        ]
      end

      it 'return built URLs with resource names' do
        urls_hash = {
          issues_url: 'https://example.com/api/v4/projects/1/issues',
          merge_request_url: 'https://example.com/api/v4/projects/1/merge_requests/2'
        }

        is_expected.to eql(urls_hash)
      end
    end

    context 'when mixed related resources (with and without params)' do
      let(:related_entities) do
        [
          { name: :branch_url, entity: API::Entities::RepoBranch, params: { id: 1, branch: 'master' } },
          { name: :commits_url, entity: API::Entities::RepoCommit, params: { id: 1 } },
          { name: :hooks_url, entity: API::Entities::Hook }
        ]
      end

      it 'return built URLs with resource names' do
        urls_hash = {
          branch_url: "https://example.com/api/v4/projects/1/repository/branches/master",
          commits_url: 'https://example.com/api/v4/projects/1/repository/commits',
          hooks_url: 'https://example.com/api/v4/hooks'
        }

        is_expected.to eql(urls_hash)
      end
    end

    context 'when related resource URI does not exist for given params' do
      let(:related_entities) do
        [
          { name: :commits_url, entity: API::Entities::RepoCommit, params: { id: 1, foo: 'i-dont-make-sense' } }
        ]
      end

      it 'ignores definition' do
        is_expected.to eql({})
      end
    end

    context 'filter by API version' do
      let(:related_entities) do
        [
          { name: :search_url, entity: API::Entities::Project, params: { query: 'foo' } }
        ]
      end

      context 'exists in v3' do
        let(:request_api_version) { 'v3' }

        it 'returns built URL according requested api version' do
          is_expected.to eql(search_url: 'https://example.com/api/v3/projects/search/foo')
        end
      end

      context 'does not exists in v4' do
        let(:request_api_version) { 'v4' }

        it 'returns no URL' do
          is_expected.to eql({})
        end
      end
    end
  end
end
