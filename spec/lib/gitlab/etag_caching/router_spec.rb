require 'spec_helper'

describe Gitlab::EtagCaching::Router do
  it 'matches issue notes endpoint' do
    env = build_env(
      '/my-group/and-subgroup/here-comes-the-project/noteable/issue/1/notes'
    )

    result = described_class.match(env)

    expect(result).to be_present
    expect(result.name).to eq 'issue_notes'
  end

  it 'matches issue title endpoint' do
    env = build_env(
      '/my-group/my-project/issues/123/rendered_title'
    )

    result = described_class.match(env)

    expect(result).to be_present
    expect(result.name).to eq 'issue_title'
  end

  it 'matches project pipelines endpoint' do
    env = build_env(
      '/my-group/my-project/pipelines.json'
    )

    result = described_class.match(env)

    expect(result).to be_present
    expect(result.name).to eq 'project_pipelines'
  end

  it 'matches commit pipelines endpoint' do
    env = build_env(
      '/my-group/my-project/commit/aa8260d253a53f73f6c26c734c72fdd600f6e6d4/pipelines.json'
    )

    result = described_class.match(env)

    expect(result).to be_present
    expect(result.name).to eq 'commit_pipelines'
  end

  it 'matches new merge request pipelines endpoint' do
    env = build_env(
      '/my-group/my-project/merge_requests/new.json'
    )

    result = described_class.match(env)

    expect(result).to be_present
    expect(result.name).to eq 'new_merge_request_pipelines'
  end

  it 'matches merge request pipelines endpoint' do
    env = build_env(
      '/my-group/my-project/merge_requests/234/pipelines.json'
    )

    result = described_class.match(env)

    expect(result).to be_present
    expect(result.name).to eq 'merge_request_pipelines'
  end

  it 'does not match blob with confusing name' do
    env = build_env(
      '/my-group/my-project/blob/master/pipelines.json'
    )

    result = described_class.match(env)

    expect(result).to be_blank
  end

  def build_env(path)
    { 'PATH_INFO' => path }
  end
end
