/* eslint-disable func-names, space-before-function-paren, no-var, prefer-rest-params, wrap-iife, camelcase, vars-on-top, object-shorthand, comma-dangle, eqeqeq, no-mixed-operators, no-return-assign, newline-per-chained-call, prefer-arrow-callback, consistent-return, one-var, one-var-declaration-per-line, prefer-template, quotes, no-unused-vars, no-else-return, max-len */

import d3 from 'd3';

var bind = function(fn, me) { return function() { return fn.apply(me, arguments); }; };

function Calendar(timestamps, calendar_activities_path) {
  this.calendar_activities_path = calendar_activities_path;
  this.clickDay = bind(this.clickDay, this);
  this.currentSelectedDate = '';
  this.daySpace = 1;
  this.daySize = 15;
  this.daySizeWithSpace = this.daySize + (this.daySpace * 2);
  this.monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  this.months = [];
  // Loop through the timestamps to create a group of objects
  // The group of objects will be grouped based on the day of the week they are
  this.timestampsTmp = [];
  var group = 0;

  var today = new Date();
  today.setHours(0, 0, 0, 0, 0);

  var oneYearAgo = new Date(today);
  oneYearAgo.setFullYear(today.getFullYear() - 1);

  var days = gl.utils.getDayDifference(oneYearAgo, today);

  for (var i = 0; i <= days; i += 1) {
    var date = new Date(oneYearAgo);
    date.setDate(date.getDate() + i);

    var day = date.getDay();
    var count = timestamps[date.format('yyyy-mm-dd')];

    // Create a new group array if this is the first day of the week
    // or if is first object
    if ((day === 0 && i !== 0) || i === 0) {
      this.timestampsTmp.push([]);
      group += 1;
    }

    var innerArray = this.timestampsTmp[group - 1];
    // Push to the inner array the values that will be used to render map
    innerArray.push({
      count: count || 0,
      date: date,
      day: day
    });
  }

  // Init color functions
  this.colorKey = this.initColorKey();
  this.color = this.initColor();
  // Init the svg element
  this.renderSvg(group);
  this.renderDays();
  this.renderMonths();
  this.renderDayTitles();
  this.renderKey();
  this.initTooltips();
}

// Add extra padding for the last month label if it is also the last column
Calendar.prototype.getExtraWidthPadding = function(group) {
  var extraWidthPadding = 0;
  var lastColMonth = this.timestampsTmp[group - 1][0].date.getMonth();
  var secondLastColMonth = this.timestampsTmp[group - 2][0].date.getMonth();

  if (lastColMonth != secondLastColMonth) {
    extraWidthPadding = 3;
  }

  return extraWidthPadding;
};

Calendar.prototype.renderSvg = function(group) {
  var width = (group + 1) * this.daySizeWithSpace + this.getExtraWidthPadding(group);
  return this.svg = d3.select('.js-contrib-calendar').append('svg').attr('width', width).attr('height', 167).attr('class', 'contrib-calendar');
};

Calendar.prototype.renderDays = function() {
  return this.svg.selectAll('g').data(this.timestampsTmp).enter().append('g').attr('transform', (group, i) => {
    _.each(group, (stamp, a) => {
      var lastMonth, lastMonthX, month, x;
      if (a === 0 && stamp.day === 0) {
        month = stamp.date.getMonth();
        x = (this.daySizeWithSpace * i + 1) + this.daySizeWithSpace;
        lastMonth = _.last(this.months);
        if (lastMonth != null) {
          lastMonthX = lastMonth.x;
        }
        if (lastMonth == null) {
          return this.months.push({
            month: month,
            x: x
          });
        } else if (month !== lastMonth.month && x - this.daySizeWithSpace !== lastMonthX) {
          return this.months.push({
            month: month,
            x: x
          });
        }
      }
    });
    return "translate(" + ((this.daySizeWithSpace * i + 1) + this.daySizeWithSpace) + ", 18)";
  }).selectAll('rect').data(function(stamp) {
    return stamp;
  }).enter().append('rect').attr('x', '0').attr('y', (stamp, i) => this.daySizeWithSpace * stamp.day)
  .attr('width', this.daySize).attr('height', this.daySize).attr('title', (stamp) => {
    var contribText, date, dateText;
    date = new Date(stamp.date);
    contribText = 'No contributions';
    if (stamp.count > 0) {
      contribText = stamp.count + " contribution" + (stamp.count > 1 ? 's' : '');
    }
    dateText = date.format('mmm d, yyyy');
    return contribText + "<br />" + (gl.utils.getDayName(date)) + " " + dateText;
  }).attr('class', 'user-contrib-cell js-tooltip').attr('fill', (stamp) => {
    if (stamp.count !== 0) {
      return this.color(Math.min(stamp.count, 40));
    } else {
      return '#ededed';
    }
  }).attr('data-container', 'body').on('click', this.clickDay);
};

Calendar.prototype.renderDayTitles = function() {
  var days;
  days = [
    {
      text: 'M',
      y: 29 + (this.daySizeWithSpace * 1)
    }, {
      text: 'W',
      y: 29 + (this.daySizeWithSpace * 3)
    }, {
      text: 'F',
      y: 29 + (this.daySizeWithSpace * 5)
    }
  ];
  return this.svg.append('g').selectAll('text').data(days).enter().append('text').attr('text-anchor', 'middle').attr('x', 8).attr('y', function(day) {
    return day.y;
  }).text(function(day) {
    return day.text;
  }).attr('class', 'user-contrib-text');
};

Calendar.prototype.renderMonths = function() {
  return this.svg.append('g').attr('direction', 'ltr').selectAll('text').data(this.months).enter().append('text').attr('x', function(date) {
    return date.x;
  }).attr('y', 10).attr('class', 'user-contrib-text').text(date => this.monthNames[date.month]);
};

Calendar.prototype.renderKey = function() {
  var keyColors;
  keyColors = ['#ededed', this.colorKey(0), this.colorKey(1), this.colorKey(2), this.colorKey(3)];
  return this.svg.append('g').attr('transform', "translate(18, " + (this.daySizeWithSpace * 8 + 16) + ")").selectAll('rect').data(keyColors).enter().append('rect').attr('width', this.daySize).attr('height', this.daySize).attr('x', (color, i) => this.daySizeWithSpace * i)
  .attr('y', 0).attr('fill', function(color) {
    return color;
  });
};

Calendar.prototype.initColor = function() {
  var colorRange;
  colorRange = ['#ededed', this.colorKey(0), this.colorKey(1), this.colorKey(2), this.colorKey(3)];
  return d3.scale.threshold().domain([0, 10, 20, 30]).range(colorRange);
};

Calendar.prototype.initColorKey = function() {
  return d3.scale.linear().range(['#acd5f2', '#254e77']).domain([0, 3]);
};

Calendar.prototype.clickDay = function(stamp) {
  var formatted_date;
  if (this.currentSelectedDate !== stamp.date) {
    this.currentSelectedDate = stamp.date;
    formatted_date = this.currentSelectedDate.getFullYear() + "-" + (this.currentSelectedDate.getMonth() + 1) + "-" + this.currentSelectedDate.getDate();
    return $.ajax({
      url: this.calendar_activities_path,
      data: {
        date: formatted_date
      },
      cache: false,
      dataType: 'html',
      beforeSend: function() {
        return $('.user-calendar-activities').html('<div class="text-center"><i class="fa fa-spinner fa-spin user-calendar-activities-loading"></i></div>');
      },
      success: function(data) {
        return $('.user-calendar-activities').html(data);
      }
    });
  } else {
    this.currentSelectedDate = '';
    return $('.user-calendar-activities').html('');
  }
};

Calendar.prototype.initTooltips = function() {
  return $('.js-contrib-calendar .js-tooltip').tooltip({
    html: true
  });
};

window.Calendar = Calendar;
