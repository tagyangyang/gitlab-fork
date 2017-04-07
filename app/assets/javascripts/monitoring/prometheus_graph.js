/* eslint-disable no-new */
/* global Flash */

import d3 from 'd3';
import statusCodes from '~/lib/utils/http_status';
import { formatRelevantDigits } from '~/lib/utils/number_utils';
import '../flash';

const prometheusContainer = '.prometheus-container';
const prometheusParentGraphContainer = '.prometheus-graphs';
const prometheusGraphsContainer = '.prometheus-graph';
const prometheusStatesContainer = '.prometheus-state';
const metricsEndpoint = 'metrics.json';
const timeFormat = d3.time.format('%H:%M');
const dayFormat = d3.time.format('%b %e, %a');
const bisectDate = d3.bisector(d => d.time).left;
const extraAddedWidthParent = 100;

class PrometheusGraph {
  constructor() {
    const $prometheusContainer = $(prometheusContainer);
    const hasMetrics = $prometheusContainer.data('has-metrics');
    this.docLink = $prometheusContainer.data('doc-link');
    this.integrationLink = $prometheusContainer.data('prometheus-integration');

    $(document).ajaxError(() => {});

    if (hasMetrics) {
      this.margin = { top: 80, right: 180, bottom: 80, left: 100 };
      this.marginLabelContainer = { top: 40, right: 0, bottom: 40, left: 0 };
      const parentContainerWidth = $(prometheusGraphsContainer).parent().width() +
      extraAddedWidthParent;
      this.originalWidth = parentContainerWidth;
      this.originalHeight = 330;
      this.width = parentContainerWidth - this.margin.left - this.margin.right;
      this.height = this.originalHeight - this.margin.top - this.margin.bottom;
      this.backOffRequestCounter = 0;
      this.configureGraph();
      this.init();
    } else {
      this.state = '.js-getting-started';
      this.updateState();
    }
  }

  createGraph() {
    Object.keys(this.graphSpecificProperties).forEach((key) => {
      const value = this.graphSpecificProperties[key];
      if (value.data.length > 0) {
        this.plotValues(key);
      }
    });
  }

  init() {
    this.getData().then((metricsResponse) => {
      let enoughData = true;
      Object.keys(metricsResponse.metrics).forEach((key) => {
        let currentKey;
        if (key === 'cpu_values' || key === 'memory_values') {
          currentKey = metricsResponse.metrics[key];
          if (Object.keys(currentKey).length === 0) {
            enoughData = false;
          }
        }
      });
      if (!enoughData) {
        this.state = '.js-loading';
        this.updateState();
      } else {
        this.transformData(metricsResponse);
        this.createGraph();
      }
    });
  }

  plotValues(key) {
    const graphSpecifics = this.graphSpecificProperties[key];

    const x = d3.time.scale()
        .range([0, this.width]);

    const y = d3.scale.linear()
        .range([this.height, 0]);

    graphSpecifics.xScale = x;
    graphSpecifics.yScale = y;

    const prometheusGraphContainer = `${prometheusGraphsContainer}[graph-type=${key}]`;

    const chart = d3.select(prometheusGraphContainer)
      .attr('width', this.width + this.margin.left + this.margin.right)
      .attr('height', this.height + this.margin.bottom + this.margin.top)
      .append('g')
        .attr('transform', `translate(${this.margin.left},${this.margin.top})`);

    const axisLabelContainer = d3.select(prometheusGraphContainer)
      .attr('width', this.originalWidth)
      .attr('height', this.originalHeight)
      .append('g')
        .attr('transform', `translate(${this.marginLabelContainer.left},${this.marginLabelContainer.top})`);

    x.domain(d3.extent(graphSpecifics.data, d => d.time));
    y.domain([0, d3.max(graphSpecifics.data.map(metricValue => metricValue.value))]);

    const xAxis = d3.svg.axis()
      .scale(x)
      .ticks(this.commonGraphProperties.axis_no_ticks)
      .orient('bottom');

    const yAxis = d3.svg.axis()
      .scale(y)
      .ticks(this.commonGraphProperties.axis_no_ticks)
      .tickSize(-this.width)
      .orient('left');

    this.createAxisLabelContainers(axisLabelContainer, key);

    chart.append('g')
      .attr('class', 'x-axis')
      .attr('transform', `translate(0,${this.height})`)
      .call(xAxis);

    chart.append('g')
      .attr('class', 'y-axis')
      .call(yAxis);

    const area = d3.svg.area()
      .x(d => x(d.time))
      .y0(this.height)
      .y1(d => y(d.value))
      .interpolate('linear');

    const line = d3.svg.line()
    .x(d => x(d.time))
    .y(d => y(d.value));

    chart.append('path')
      .datum(graphSpecifics.data)
      .attr('d', area)
      .attr('class', 'metric-area')
      .attr('fill', graphSpecifics.area_fill_color);

    chart.append('path')
      .datum(graphSpecifics.data)
      .attr('class', 'metric-line')
      .attr('stroke', graphSpecifics.line_color)
      .attr('fill', 'none')
      .attr('stroke-width', this.commonGraphProperties.area_stroke_width)
      .attr('d', line);

    // Overlay area for the mouseover events
    chart.append('rect')
      .attr('class', 'prometheus-graph-overlay')
      .attr('width', this.width)
      .attr('height', this.height)
      .on('mousemove', this.handleMouseOverGraph.bind(this, prometheusGraphContainer));
  }

  // The legends from the metric
  createAxisLabelContainers(axisLabelContainer, key) {
    const graphSpecifics = this.graphSpecificProperties[key];

    axisLabelContainer.append('line')
      .attr('class', 'label-x-axis-line')
      .attr('stroke', '#000000')
      .attr('stroke-width', '1')
      .attr({
        x1: 10,
        y1: this.originalHeight - this.margin.top,
        x2: (this.originalWidth - this.margin.right) + 10,
        y2: this.originalHeight - this.margin.top,
      });

    axisLabelContainer.append('line')
      .attr('class', 'label-y-axis-line')
      .attr('stroke', '#000000')
      .attr('stroke-width', '1')
      .attr({
        x1: 10,
        y1: 0,
        x2: 10,
        y2: this.originalHeight - this.margin.top,
      });

    axisLabelContainer.append('rect')
      .attr('class', 'rect-axis-text')
      .attr('x', 0)
      .attr('y', 50)
      .attr('width', 30)
      .attr('height', 150);

    axisLabelContainer.append('text')
      .attr('class', 'label-axis-text')
      .attr('text-anchor', 'middle')
      .attr('transform', `translate(15, ${(this.originalHeight - this.margin.top) / 2}) rotate(-90)`)
      .text(graphSpecifics.graph_legend_title);

    axisLabelContainer.append('rect')
      .attr('class', 'rect-axis-text')
      .attr('x', (this.originalWidth / 2) - this.margin.right)
      .attr('y', this.originalHeight - 100)
      .attr('width', 30)
      .attr('height', 80);

    axisLabelContainer.append('text')
      .attr('class', 'label-axis-text')
      .attr('x', (this.originalWidth / 2) - this.margin.right)
      .attr('y', this.originalHeight - this.margin.top)
      .attr('dy', '.35em')
      .text('Time');

    // Legends

    // Metric Usage
    axisLabelContainer.append('rect')
      .attr('x', this.originalWidth - 170)
      .attr('y', (this.originalHeight / 2) - 60)
      .style('fill', graphSpecifics.area_fill_color)
      .attr('width', 20)
      .attr('height', 35);

    axisLabelContainer.append('text')
      .attr('class', 'text-metric-title')
      .attr('x', this.originalWidth - 140)
      .attr('y', (this.originalHeight / 2) - 50)
      .text('Average');

    axisLabelContainer.append('text')
      .attr('class', 'text-metric-usage')
      .attr('x', this.originalWidth - 140)
      .attr('y', (this.originalHeight / 2) - 25);
  }

  handleMouseOverGraph(prometheusGraphContainer) {
    const rectOverlay = document.querySelector(`${prometheusGraphContainer} .prometheus-graph-overlay`);
    const currentXCoordinate = d3.mouse(rectOverlay)[0];

    Object.keys(this.graphSpecificProperties).forEach((key) => {
      const currentGraphProps = this.graphSpecificProperties[key];
      const timeValueOverlay = currentGraphProps.xScale.invert(currentXCoordinate);
      const overlayIndex = bisectDate(currentGraphProps.data, timeValueOverlay, 1);
      const d0 = currentGraphProps.data[overlayIndex - 1];
      const d1 = currentGraphProps.data[overlayIndex];
      const evalTime = timeValueOverlay - d0.time > d1.time - timeValueOverlay;
      const currentData = evalTime ? d1 : d0;
      const currentTimeCoordinate = currentGraphProps.xScale(currentData.time);
      const currentPrometheusGraphContainer = `${prometheusGraphsContainer}[graph-type=${key}]`;
      const maxValueFromData = d3.max(currentGraphProps.data.map(metricValue => metricValue.value));
      const maxMetricValue = currentGraphProps.yScale(maxValueFromData);

      // Clear up all the pieces of the flag
      d3.selectAll(`${currentPrometheusGraphContainer} .selected-metric-line`).remove();
      d3.selectAll(`${currentPrometheusGraphContainer} .circle-metric`).remove();
      d3.selectAll(`${currentPrometheusGraphContainer} .rect-text-metric`).remove();
      d3.selectAll(`${currentPrometheusGraphContainer} .text-metric`).remove();

      const currentChart = d3.select(currentPrometheusGraphContainer).select('g');
      currentChart.append('line')
      .attr('class', 'selected-metric-line')
      .attr({
        x1: currentTimeCoordinate,
        y1: currentGraphProps.yScale(0),
        x2: currentTimeCoordinate,
        y2: maxMetricValue,
      });

      currentChart.append('circle')
        .attr('class', 'circle-metric')
        .attr('fill', currentGraphProps.line_color)
        .attr('cx', currentTimeCoordinate)
        .attr('cy', currentGraphProps.yScale(currentData.value))
        .attr('r', this.commonGraphProperties.circle_radius_metric);

      // The little box with text
      const rectTextMetric = currentChart.append('g')
        .attr('class', 'rect-text-metric')
        .attr('translate', `(${currentTimeCoordinate}, ${currentGraphProps.yScale(currentData.value)})`);

      rectTextMetric.append('rect')
        .attr('class', 'rect-metric')
        .attr('x', currentTimeCoordinate + 10)
        .attr('y', maxMetricValue)
        .attr('width', this.commonGraphProperties.rect_text_width)
        .attr('height', this.commonGraphProperties.rect_text_height);

      rectTextMetric.append('text')
        .attr('class', 'text-metric')
        .attr('x', currentTimeCoordinate + 35)
        .attr('y', maxMetricValue + 35)
        .text(timeFormat(currentData.time));

      rectTextMetric.append('text')
        .attr('class', 'text-metric-date')
        .attr('x', currentTimeCoordinate + 15)
        .attr('y', maxMetricValue + 15)
        .text(dayFormat(currentData.time));

      let currentMetricValue = formatRelevantDigits(currentData.value);
      if (key === 'cpu_values') {
        currentMetricValue = `${currentMetricValue}%`;
      } else {
        currentMetricValue = `${currentMetricValue} MB`;
      }

      d3.select(`${currentPrometheusGraphContainer} .text-metric-usage`)
        .text(currentMetricValue);
    });
  }

  configureGraph() {
    this.graphSpecificProperties = {
      cpu_values: {
        area_fill_color: '#edf3fc',
        line_color: '#5b99f7',
        graph_legend_title: 'CPU Usage (Cores)',
        data: [],
        xScale: {},
        yScale: {},
      },
      memory_values: {
        area_fill_color: '#fca326',
        line_color: '#fc6d26',
        graph_legend_title: 'Memory Usage (MB)',
        data: [],
        xScale: {},
        yScale: {},
      },
    };

    this.commonGraphProperties = {
      area_stroke_width: 2,
      median_total_characters: 8,
      circle_radius_metric: 5,
      rect_text_width: 90,
      rect_text_height: 40,
      axis_no_ticks: 3,
    };
  }

  getData() {
    const maxNumberOfRequests = 3;
    return gl.utils.backOff((next, stop) => {
      $.ajax({
        url: metricsEndpoint,
        dataType: 'json',
      })
      .done((data, statusText, resp) => {
        if (resp.status === statusCodes.NO_CONTENT) {
          this.backOffRequestCounter = this.backOffRequestCounter += 1;
          if (this.backOffRequestCounter < maxNumberOfRequests) {
            next();
          } else {
            stop({
              status: resp.status,
              metrics: data,
            });
          }
        } else {
          stop({
            status: resp.status,
            metrics: data,
          });
        }
      }).fail(stop);
    })
    .then((resp) => {
      if (resp.status === statusCodes.NO_CONTENT) {
        return {};
      }
      return resp.metrics;
    })
    .catch(() => {
      this.state = '.js-unable-to-connect';
      this.updateState();
    });
  }

  transformData(metricsResponse) {
    Object.keys(metricsResponse.metrics).forEach((key) => {
      if (key === 'cpu_values' || key === 'memory_values') {
        const metricValues = (metricsResponse.metrics[key])[0];
        if (metricValues !== undefined) {
          this.graphSpecificProperties[key].data = metricValues.values.map(metric => ({
            time: new Date(metric[0] * 1000),
            value: metric[1],
          }));
        }
      }
    });
  }

  updateState() {
    const $statesContainer = $(prometheusStatesContainer);
    $(prometheusParentGraphContainer).hide();
    $(`${this.state}`, $statesContainer).removeClass('hidden');
    $(prometheusStatesContainer).show();
  }
}

export default PrometheusGraph;
