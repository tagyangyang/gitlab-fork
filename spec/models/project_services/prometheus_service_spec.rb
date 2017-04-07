require 'spec_helper'

describe PrometheusService, models: true, caching: true do
  include PrometheusHelpers
  include ReactiveCachingHelpers

  let(:project) { create(:prometheus_project) }
  let(:service) { project.prometheus_service }

  describe "Associations" do
    it { is_expected.to belong_to :project }
  end

  describe 'Validations' do
    context 'when service is active' do
      before { subject.active = true }

      it { is_expected.to validate_presence_of(:api_url) }
    end

    context 'when service is inactive' do
      before { subject.active = false }

      it { is_expected.not_to validate_presence_of(:api_url) }
    end
  end

  describe '#test' do
    let!(:req_stub) { stub_prometheus_request(prometheus_query_url('1'), body: prometheus_value_body('vector')) }

    context 'success' do
      it 'reads the discovery endpoint' do
        expect(service.test[:success]).to be_truthy
        expect(req_stub).to have_been_requested
      end
    end

    context 'failure' do
      let!(:req_stub) { stub_prometheus_request(prometheus_query_url('1'), status: 404) }

      it 'fails to read the discovery endpoint' do
        expect(service.test[:success]).to be_falsy
        expect(req_stub).to have_been_requested
      end
    end
  end

  describe '#metrics' do
    let(:environment) { build_stubbed(:environment, slug: 'env-slug') }

    around do |example|
      Timecop.freeze { example.run }
    end

    context 'with valid data without time range' do
      subject { service.metrics(environment) }

      before do
        stub_reactive_cache(service, prometheus_data, 'env-slug', nil, nil)
      end

      it 'returns reactive data' do
        is_expected.to eq(prometheus_data)
      end
    end

    context 'with valid data with time range' do
      let(:t_start) { 1.hour.ago.utc }
      let(:t_end) { Time.now.utc }
      subject { service.metrics(environment, timeframe_start: t_start, timeframe_end: t_end) }

      before do
        stub_reactive_cache(service, prometheus_data, 'env-slug', t_start, t_end)
      end

      it 'returns reactive data' do
        is_expected.to eq(prometheus_data)
      end
    end
  end

  describe '#calculate_reactive_cache' do
    let(:environment) { build_stubbed(:environment, slug: 'env-slug') }

    around do |example|
      Timecop.freeze { example.run }
    end

    subject do
      service.calculate_reactive_cache(environment.slug, nil, nil)
    end

    context 'when service is inactive' do
      before do
        service.active = false
      end

      it { is_expected.to be_nil }
    end

    context 'when Prometheus responds with valid data' do
      before do
        stub_all_prometheus_requests(environment.slug)
      end

      it { expect(subject.to_json).to eq(prometheus_data.to_json) }
    end

    [404, 500].each do |status|
      context "when Prometheus responds with #{status}" do
        before do
          stub_all_prometheus_requests(environment.slug, status: status, body: 'QUERY FAILED!')
        end

        it { is_expected.to eq(success: false, result: %(#{status} - "QUERY FAILED!")) }
      end
    end
  end
end
