/* eslint-disable func-names, space-before-function-paren, wrap-iife, no-var, no-underscore-dangle, prefer-arrow-callback, max-len, one-var, one-var-declaration-per-line, no-unused-vars, object-shorthand, comma-dangle, no-else-return, no-self-compare, consistent-return, no-param-reassign, no-shadow */
/* global Issuable */
/* global ListMilestone */

import Vue from 'vue';

(function() {
  this.MilestoneSelect = (function() {
    function MilestoneSelect(currentProject, els) {
      var _this, $els;
      if (currentProject != null) {
        _this = this;
        this.currentProject = JSON.parse(currentProject);
      }

      $els = $(els);

      if (!els) {
        $els = $('.js-milestone-select');
      }

      $els.each(function(i, dropdown) {
        var $block, $dropdown, $loading, $selectbox, $sidebarCollapsedValue, $value, abilityName, collapsedSidebarLabelTemplate, defaultLabel, issuableId, issueUpdateURL, milestoneLinkNoneTemplate, milestoneLinkTemplate, milestonesUrl, projectId, selectedMilestone, showAny, showNo, showUpcoming, showStarted, useId, showMenuAbove;
        $dropdown = $(dropdown);
        projectId = $dropdown.data('project-id');
        milestonesUrl = $dropdown.data('milestones');
        issueUpdateURL = $dropdown.data('issueUpdate');
        selectedMilestone = $dropdown.data('selected');
        showNo = $dropdown.data('show-no');
        showAny = $dropdown.data('show-any');
        showMenuAbove = $dropdown.data('showMenuAbove');
        showUpcoming = $dropdown.data('show-upcoming');
        showStarted = $dropdown.data('show-started');
        useId = $dropdown.data('use-id');
        defaultLabel = $dropdown.data('default-label');
        issuableId = $dropdown.data('issuable-id');
        abilityName = $dropdown.data('ability-name');
        $selectbox = $dropdown.closest('.selectbox');
        $block = $selectbox.closest('.block');
        $sidebarCollapsedValue = $block.find('.sidebar-collapsed-icon');
        $value = $block.find('.value');
        $loading = $block.find('.block-loading').fadeOut();
        if (issueUpdateURL) {
          milestoneLinkTemplate = _.template('<a href="/<%- full_path %>/milestones/<%- iid %>" class="bold has-tooltip" data-container="body" title="<%- remaining %>"><%- title %></a>');
          milestoneLinkNoneTemplate = '<span class="no-value">None</span>';
          collapsedSidebarLabelTemplate = _.template('<span class="has-tooltip" data-container="body" title="<%- remaining %>" data-placement="left"> <%- title %> </span>');
        }
        return $dropdown.glDropdown({
          showMenuAbove: showMenuAbove,
          data: function(term, callback) {
            return $.ajax({
              url: milestonesUrl
            }).done(function(data) {
              var extraOptions = [];
              if (showAny) {
                extraOptions.push({
                  id: 0,
                  name: '',
                  title: 'Any Milestone'
                });
              }
              if (showNo) {
                extraOptions.push({
                  id: -1,
                  name: 'No Milestone',
                  title: 'No Milestone'
                });
              }
              if (showUpcoming) {
                extraOptions.push({
                  id: -2,
                  name: '#upcoming',
                  title: 'Upcoming'
                });
              }
              if (showStarted) {
                extraOptions.push({
                  id: -3,
                  name: '#started',
                  title: 'Started'
                });
              }
              if (extraOptions.length) {
                extraOptions.push('divider');
              }

              callback(extraOptions.concat(data));
              if (showMenuAbove) {
                $dropdown.data('glDropdown').positionMenuAbove();
              }
            });
          },
          filterable: true,
          search: {
            fields: ['title']
          },
          selectable: true,
          toggleLabel: function(selected, el, e) {
            if (selected && 'id' in selected && $(el).hasClass('is-active')) {
              return selected.title;
            } else {
              return defaultLabel;
            }
          },
          defaultLabel: defaultLabel,
          fieldName: $dropdown.data('field-name'),
          text: function(milestone) {
            return _.escape(milestone.title);
          },
          id: function(milestone) {
            if (!useId && !$dropdown.is('.js-issuable-form-dropdown')) {
              return milestone.name;
            } else {
              return milestone.id;
            }
          },
          isSelected: function(milestone) {
            return milestone.name === selectedMilestone;
          },
          hidden: function() {
            $selectbox.hide();
            // display:block overrides the hide-collapse rule
            return $value.css('display', '');
          },
          vue: $dropdown.hasClass('js-issue-board-sidebar'),
          clicked: function(selected, $el, e) {
            var data, isIssueIndex, isMRIndex, page, boardsStore;
            page = $('body').data('page');
            isIssueIndex = page === 'projects:issues:index';
            isMRIndex = (page === page && page === 'projects:merge_requests:index');
            if ($dropdown.hasClass('js-filter-bulk-update') || $dropdown.hasClass('js-issuable-form-dropdown')) {
              e.preventDefault();
              return;
            }

            if ($dropdown.closest('.add-issues-modal').length) {
              boardsStore = gl.issueBoards.ModalStore.store.filter;
            }

            if (boardsStore) {
              boardsStore[$dropdown.data('field-name')] = selected.name;
              e.preventDefault();
            } else if ($dropdown.hasClass('js-filter-submit') && (isIssueIndex || isMRIndex)) {
              if (selected.name != null) {
                selectedMilestone = selected.name;
              } else {
                selectedMilestone = '';
              }
              return Issuable.filterResults($dropdown.closest('form'));
            } else if ($dropdown.hasClass('js-filter-submit')) {
              return $dropdown.closest('form').submit();
            } else if ($dropdown.hasClass('js-issue-board-sidebar')) {
              if (selected.id !== -1) {
                Vue.set(gl.issueBoards.BoardsStore.detail.issue, 'milestone', new ListMilestone({
                  id: selected.id,
                  title: selected.name
                }));
              } else {
                Vue.delete(gl.issueBoards.BoardsStore.detail.issue, 'milestone');
              }

              $dropdown.trigger('loading.gl.dropdown');
              $loading.removeClass('hidden').fadeIn();

              gl.issueBoards.BoardsStore.detail.issue.update($dropdown.attr('data-issue-update'))
                .then(function () {
                  $dropdown.trigger('loaded.gl.dropdown');
                  $loading.fadeOut();
                })
                .catch(function () {
                  $loading.fadeOut();
                });
            } else {
              selected = $selectbox.find('input[type="hidden"]').val();
              data = {};
              data[abilityName] = {};
              data[abilityName].milestone_id = selected != null ? selected : null;
              $loading.removeClass('hidden').fadeIn();
              $dropdown.trigger('loading.gl.dropdown');
              return $.ajax({
                type: 'PUT',
                url: issueUpdateURL,
                data: data
              }).done(function(data) {
                $dropdown.trigger('loaded.gl.dropdown');
                $loading.fadeOut();
                $selectbox.hide();
                $value.css('display', '');
                if (data.milestone != null) {
                  data.milestone.full_path = _this.currentProject.full_path;
                  data.milestone.remaining = gl.utils.timeFor(data.milestone.due_date);
                  $value.html(milestoneLinkTemplate(data.milestone));
                  return $sidebarCollapsedValue.find('span').html(collapsedSidebarLabelTemplate(data.milestone));
                } else {
                  $value.html(milestoneLinkNoneTemplate);
                  return $sidebarCollapsedValue.find('span').text('No');
                }
              });
            }
          }
        });
      });
    }

    return MilestoneSelect;
  })();
}).call(window);
