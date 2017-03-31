/* eslint-disable func-names, space-before-function-paren, no-var, prefer-rest-params, wrap-iife, no-use-before-define, no-param-reassign, quotes, yoda, no-else-return, consistent-return, comma-dangle, object-shorthand, prefer-template, one-var, one-var-declaration-per-line, no-unused-vars, max-len, vars-on-top */
/* global Breakpoints */
$(() => {
  var bind = function(fn, me) { return function() { return fn.apply(me, arguments); }; };
  var AUTO_SCROLL_OFFSET = 75;
  var DOWN_BUILD_TRACE = '#down-build-trace';

  window.Build = (function() {
    Build.timeout = null;

    Build.state = null;

    function Build(options) {
      this.options = options || $('.js-build-options').data();

      this.pageUrl = this.options.pageUrl;
      this.buildUrl = this.options.buildUrl;
      this.buildStatus = this.options.buildStatus;
      this.state = this.options.logState;
      this.buildStage = this.options.buildStage;
      this.updateDropdown = bind(this.updateDropdown, this);
      this.$document = $(document);
      this.$body = $('body');
      this.$buildTrace = $('#build-trace');
      this.$autoScrollContainer = $('.autoscroll-container');
      this.$autoScrollStatus = $('#autoscroll-status');
      this.$autoScrollStatusText = this.$autoScrollStatus.find('.status-text');
      this.$upBuildTrace = $('#up-build-trace');
      this.$downBuildTrace = $(DOWN_BUILD_TRACE);
      this.$scrollTopBtn = $('#scroll-top');
      this.$scrollBottomBtn = $('#scroll-bottom');
      this.$buildRefreshAnimation = $('.js-build-refresh');

      clearTimeout(Build.timeout);
      // Init breakpoint checker
      this.bp = Breakpoints.get();

      this.initSidebar();
      this.$buildScroll = $('#js-build-scroll');
      this.$truncatedInfo = $('.js-truncated-info');

      this.populateJobs(this.buildStage);
      this.updateStageDropdownText(this.buildStage);
      this.sidebarOnResize();

      this.$document
        .off('click', '.js-sidebar-build-toggle')
        .on('click', '.js-sidebar-build-toggle', this.sidebarOnClick.bind(this));

      this.$document
        .off('click', '.stage-item')
        .on('click', '.stage-item', this.updateDropdown);

      this.$document.on('scroll', this.initScrollMonitor.bind(this));

      $(window)
        .off('resize.build')
        .on('resize.build', this.sidebarOnResize.bind(this));

      $('a', this.$buildScroll)
        .off('click.stepTrace')
        .on('click.stepTrace', this.stepTrace);

      this.updateArtifactRemoveDate();
      this.initScrollButtonAffix();
      this.invokeBuildTrace();
    }

    Build.prototype.initSidebar = function() {
      this.$sidebar = $('.js-build-sidebar');
      this.$sidebar.niceScroll();
      this.$document.off('click', '.js-sidebar-build-toggle').on('click', '.js-sidebar-build-toggle', this.toggleSidebar);
    };

    Build.prototype.location = function() {
      return window.location.href.split("#")[0];
    };

    Build.prototype.invokeBuildTrace = function() {
      if (this.location() === this.pageUrl) {
        return this.getBuildTrace();
      }
    };

    Build.prototype.getBuildTrace = function() {
      return $.ajax({
        url: this.pageUrl + '/trace.json',
        dataType: 'json',
        data: {
          state: this.state
        },
        success: ((log) => {
          const $buildContainer = $('.js-build-output');

          if (log.state) {
            this.state = log.state;
          }

          if (log.append) {
            $buildContainer.append(log.html);
          } else {
            $buildContainer.html(log.html);
          }

          this.$truncatedInfo.toggleClass('hidden', !log.truncated);

          if (log.status !== this.buildStatus) {
            let pageUrl = this.pageUrl;

            if (this.$autoScrollStatus.data('state') === 'enabled') {
              pageUrl += DOWN_BUILD_TRACE;
            }

            return gl.utils.visitUrl(pageUrl);
          } else {
            this.checkAutoscroll();
          }

          if (!log.complete) {
            Build.timeout = setTimeout(() => {
              this.invokeBuildTrace();
            }, 4000);
          } else {
            this.$buildRefreshAnimation.remove();
          }

          return this.initScrollMonitor();
        }),
        error: () => {
          this.$buildRefreshAnimation.remove();
          return this.initScrollMonitor();
        }
      });
    };

    Build.prototype.checkAutoscroll = function() {
      if (this.$autoScrollStatus.data("state") === "enabled") {
        return $("html,body").scrollTop(this.$buildTrace.height());
      }

      // Handle a situation where user started new build
      // but never scrolled a page
      if (!this.$scrollTopBtn.is(':visible') &&
          !this.$scrollBottomBtn.is(':visible') &&
          !gl.utils.isInViewport(this.$downBuildTrace.get(0))) {
        this.$scrollBottomBtn.show();
      }
    };

    Build.prototype.initScrollButtonAffix = function() {
      // Hide everything initially
      this.$scrollTopBtn.hide();
      this.$scrollBottomBtn.hide();
      this.$autoScrollContainer.hide();
    };

    // Page scroll listener to detect if user has scrolling page
    // and handle following cases
    // 1) User is at Top of Build Log;
    //      - Hide Top Arrow button
    //      - Show Bottom Arrow button
    //      - Disable Autoscroll and hide indicator (when build is running)
    // 2) User is at Bottom of Build Log;
    //      - Show Top Arrow button
    //      - Hide Bottom Arrow button
    //      - Enable Autoscroll and show indicator (when build is running)
    // 3) User is somewhere in middle of Build Log;
    //      - Show Top Arrow button
    //      - Show Bottom Arrow button
    //      - Disable Autoscroll and hide indicator (when build is running)
    Build.prototype.initScrollMonitor = function() {
      if (!gl.utils.isInViewport(this.$upBuildTrace.get(0)) &&
        !gl.utils.isInViewport(this.$downBuildTrace.get(0))) {
        // User is somewhere in middle of Build Log

        this.$scrollTopBtn.show();
        this.fixTruncatedInfo();

        if (this.buildStatus === 'success' || this.buildStatus === 'failed') { // Check if Build is completed
          this.$scrollBottomBtn.show();
        } else if (this.$buildRefreshAnimation.is(':visible') && !gl.utils.isInViewport(this.$buildRefreshAnimation.get(0))) {
          this.$scrollBottomBtn.show();
        } else {
          this.$scrollBottomBtn.hide();
        }

        // Hide Autoscroll Status Indicator
        if (this.$scrollBottomBtn.is(':visible')) {
          this.$autoScrollContainer.hide();
          this.$autoScrollStatusText.removeClass('animate');
        } else {
          this.$autoScrollContainer.css({ top: this.$body.outerHeight() - AUTO_SCROLL_OFFSET }).show();
          this.$autoScrollStatusText.addClass('animate');
        }
      } else if (gl.utils.isInViewport(this.$upBuildTrace.get(0)) &&
        !gl.utils.isInViewport(this.$downBuildTrace.get(0))) {
        // User is at Top of Build Log

        this.$scrollTopBtn.hide();
        this.$scrollBottomBtn.show();
        this.unFixTruncatedInfo();

        this.$autoScrollContainer.hide();
        this.$autoScrollStatusText.removeClass('animate');
      } else if ((!gl.utils.isInViewport(this.$upBuildTrace.get(0)) && gl.utils.isInViewport(this.$downBuildTrace.get(0))) ||
                 (this.$buildRefreshAnimation.is(':visible') && gl.utils.isInViewport(this.$buildRefreshAnimation.get(0)))) {
        // User is at Bottom of Build Log

        this.$scrollTopBtn.show();
        this.$scrollBottomBtn.hide();
        this.fixTruncatedInfo();

        // Show and Reposition Autoscroll Status Indicator
        this.$autoScrollContainer.css({ top: this.$body.outerHeight() - AUTO_SCROLL_OFFSET }).show();
        this.$autoScrollStatusText.addClass('animate');
      } else if (gl.utils.isInViewport(this.$upBuildTrace.get(0)) && gl.utils.isInViewport(this.$downBuildTrace.get(0))) {
        // Build Log height is small

        this.$scrollTopBtn.hide();
        this.$scrollBottomBtn.hide();
        this.unFixTruncatedInfo();

        // Hide Autoscroll Status Indicator
        this.$autoScrollContainer.hide();
        this.$autoScrollStatusText.removeClass('animate');
      }

      if (this.buildStatus === "running" || this.buildStatus === "pending") {
        // Check if Refresh Animation is in Viewport and enable Autoscroll, disable otherwise.
        this.$autoScrollStatus.data("state", gl.utils.isInViewport(this.$buildRefreshAnimation.get(0)) ? 'enabled' : 'disabled');
      }
    };

    Build.prototype.shouldHideSidebarForViewport = function() {
      var bootstrapBreakpoint;
      bootstrapBreakpoint = this.bp.getBreakpointSize();
      return bootstrapBreakpoint === 'xs' || bootstrapBreakpoint === 'sm';
    };

    Build.prototype.toggleSidebar = function(shouldHide) {
      var shouldShow = typeof shouldHide === 'boolean' ? !shouldHide : undefined;
      this.$buildScroll.toggleClass('sidebar-expanded', shouldShow)
        .toggleClass('sidebar-collapsed', shouldHide);
      this.$truncatedInfo.toggleClass('sidebar-expanded', shouldShow)
        .toggleClass('sidebar-collapsed', shouldHide);
      this.$sidebar.toggleClass('right-sidebar-expanded', shouldShow)
        .toggleClass('right-sidebar-collapsed', shouldHide);
    };

    Build.prototype.sidebarOnResize = function() {
      this.toggleSidebar(this.shouldHideSidebarForViewport());
    };

    Build.prototype.sidebarOnClick = function() {
      if (this.shouldHideSidebarForViewport()) this.toggleSidebar();
    };

    Build.prototype.updateArtifactRemoveDate = function() {
      var $date, date;
      $date = $('.js-artifacts-remove');
      if ($date.length) {
        date = $date.text();
        return $date.text(gl.utils.timeFor(new Date(date.replace(/([0-9]+)-([0-9]+)-([0-9]+)/g, '$1/$2/$3')), ' '));
      }
    };

    Build.prototype.populateJobs = function(stage) {
      $('.build-job').hide();
      $('.build-job[data-stage="' + stage + '"]').show();
    };

    Build.prototype.updateStageDropdownText = function(stage) {
      $('.stage-selection').text(stage);
    };

    Build.prototype.updateDropdown = function(e) {
      e.preventDefault();
      var stage = e.currentTarget.text;
      this.updateStageDropdownText(stage);
      this.populateJobs(stage);
    };

    Build.prototype.stepTrace = function(e) {
      var $currentTarget;
      e.preventDefault();
      $currentTarget = $(e.currentTarget);
      $.scrollTo($currentTarget.attr('href'), {
        offset: 0
      });
    };

    Build.prototype.fixTruncatedInfo = () => {
      $('.js-truncated-info')
        .removeClass('truncated-info-absolute')
        .addClass('truncated-info-fixed');
    };

    Build.prototype.unFixTruncatedInfo = () => {
      $('.js-truncated-info')
        .removeClass('truncated-info-fixed')
        .addClass('truncated-info-absolute');
    };

    return Build;
  })();

});
