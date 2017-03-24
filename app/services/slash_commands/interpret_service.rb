module SlashCommands
  class InterpretService < BaseService
    include Gitlab::SlashCommands::Dsl

    attr_reader :issuable, :options

    # Takes a text and interprets the commands that are extracted from it.
    # Returns the content without commands, and hash of changes to be applied to a record.
    def execute(content, issuable)
      @issuable = issuable
      @updates = {}
      opts = {
        issuable:     @issuable,
        current_user: current_user,
        project:      project,
        params:       params
      }

      content, commands = extractor.extract_commands(content, opts)
      extract_updates(commands, opts)
      [content, @updates]
    end

    # Takes a text and interprets the commands that are extracted from it.
    # Returns the content without commands, and array of changes humanized.
    def explain(content, issuable)
      @issuable = issuable
      opts = {
        issuable:     @issuable,
        current_user: current_user,
        project:      project
      }

      content, commands = extractor.extract_commands(content, opts)
      commands = humanize_commands(commands, opts)
      [content, commands]
    end

    private

    def extractor
      Gitlab::SlashCommands::Extractor.new(self.class.command_definitions)
    end

    desc do
      "Close this #{issuable.to_ability_name.humanize(capitalize: false)}"
    end
    humanized do
      "Closes this #{issuable.to_ability_name.humanize(capitalize: false)}."
    end
    condition do
      issuable.persisted? &&
        issuable.open? &&
        current_user.can?(:"update_#{issuable.to_ability_name}", issuable)
    end
    command :close do
      @updates[:state_event] = 'close'
    end

    desc do
      "Reopen this #{issuable.to_ability_name.humanize(capitalize: false)}"
    end
    humanized do
      "Reopens this #{issuable.to_ability_name.humanize(capitalize: false)}."
    end
    condition do
      issuable.persisted? &&
        issuable.closed? &&
        current_user.can?(:"update_#{issuable.to_ability_name}", issuable)
    end
    command :reopen do
      @updates[:state_event] = 'reopen'
    end

    desc 'Merge (when the pipeline succeeds)'
    humanized do
      'Merges this merge request when the pipeline succeeds.'
    end
    condition do
      last_diff_sha = params && params[:merge_request_diff_head_sha]
      issuable.is_a?(MergeRequest) &&
        issuable.persisted? &&
        issuable.mergeable_with_slash_command?(current_user, autocomplete_precheck: !last_diff_sha, last_diff_sha: last_diff_sha)
    end
    command :merge do
      @updates[:merge] = params[:merge_request_diff_head_sha]
    end

    desc 'Change title'
    humanized do |title_param|
      "Changes the title to #{title_param}."
    end
    params '<New title>'
    condition do
      issuable.persisted? &&
        current_user.can?(:"update_#{issuable.to_ability_name}", issuable)
    end
    command :title do |title_param|
      @updates[:title] = title_param
    end

    desc 'Assign'
    humanized do |assignee_param|
      "Assigns #{assignee_param}."
    end
    params '@user'
    condition do
      current_user.can?(:"admin_#{issuable.to_ability_name}", project)
    end
    command :assign do |assignee_param|
      user = extract_references(assignee_param, :user).first
      user ||= User.find_by(username: assignee_param)

      @updates[:assignee_id] = user.id if user
    end

    desc 'Remove assignee'
    humanized do
      "Removes assignee #{issuable.assignee.to_reference}."
    end
    condition do
      issuable.persisted? &&
        issuable.assignee_id? &&
        current_user.can?(:"admin_#{issuable.to_ability_name}", project)
    end
    command :unassign do
      @updates[:assignee_id] = nil
    end

    desc 'Set milestone'
    humanized do |milestone_param|
      milestone = extract_references(milestone_param, :milestone).first
      "Sets the milestone to #{milestone.to_reference}."
    end
    params '%"milestone"'
    condition do
      current_user.can?(:"admin_#{issuable.to_ability_name}", project) &&
        project.milestones.active.any?
    end
    command :milestone do |milestone_param|
      milestone = extract_references(milestone_param, :milestone).first
      milestone ||= project.milestones.find_by(title: milestone_param.strip)

      @updates[:milestone_id] = milestone.id if milestone
    end

    desc 'Remove milestone'
    humanized do
      "Removes #{issuable.milestone.to_reference} milestone."
    end
    condition do
      issuable.persisted? &&
        issuable.milestone_id? &&
        current_user.can?(:"admin_#{issuable.to_ability_name}", project)
    end
    command :remove_milestone do
      @updates[:milestone_id] = nil
    end

    desc 'Add label(s)'
    humanized do |labels_param|
      labels = find_label_references(labels_param)

      "Adds #{labels.join(' ')} #{'label'.pluralize(labels.count)}."
    end
    params '~label1 ~"label 2"'
    condition do
      available_labels = LabelsFinder.new(current_user, project_id: project.id).execute

      current_user.can?(:"admin_#{issuable.to_ability_name}", project) &&
        available_labels.any?
    end
    command :label do |labels_param|
      label_ids = find_label_ids(labels_param)

      if label_ids.any?
        @updates[:add_label_ids] ||= []
        @updates[:add_label_ids] += label_ids

        @updates[:add_label_ids].uniq!
      end
    end

    desc 'Remove all or specific label(s)'
    humanized do |labels_param = nil|
      if labels_param.present?
        labels = find_label_references(labels_param)
        label_count = labels.count
        "Removes #{labels.join(' ')} #{'label'.pluralize(label_count)}."
      else
        'Removes all labels.'
      end
    end
    params '~label1 ~"label 2"'
    condition do
      issuable.persisted? &&
        issuable.labels.any? &&
        current_user.can?(:"admin_#{issuable.to_ability_name}", project)
    end
    command :unlabel do |labels_param = nil|
      if labels_param.present?
        label_ids = find_label_ids(labels_param)

        if label_ids.any?
          @updates[:remove_label_ids] ||= []
          @updates[:remove_label_ids] += label_ids

          @updates[:remove_label_ids].uniq!
        end
      else
        @updates[:label_ids] = []
      end
    end

    desc 'Replace all label(s)'
    humanized do |labels_param|
      labels = find_label_references(labels_param)
      "Replaces all labels with #{labels.join(' ')} #{'label'.pluralize(labels.count)}."
    end
    params '~label1 ~"label 2"'
    condition do
      issuable.persisted? &&
        issuable.labels.any? &&
        current_user.can?(:"admin_#{issuable.to_ability_name}", project)
    end
    command :relabel do |labels_param|
      label_ids = find_label_ids(labels_param)

      if label_ids.any?
        @updates[:label_ids] ||= []
        @updates[:label_ids] += label_ids

        @updates[:label_ids].uniq!
      end
    end

    desc 'Add a todo'
    humanized 'Adds a todo.'
    condition do
      issuable.persisted? &&
        !TodoService.new.todo_exist?(issuable, current_user)
    end
    command :todo do
      @updates[:todo_event] = 'add'
    end

    desc 'Mark todo as done'
    humanized 'Marks todo as done.'
    condition do
      issuable.persisted? &&
        TodoService.new.todo_exist?(issuable, current_user)
    end
    command :done do
      @updates[:todo_event] = 'done'
    end

    desc 'Subscribe'
    humanized do
      "Subscribes to this #{issuable.to_ability_name.humanize(capitalize: false)}."
    end
    condition do
      issuable.persisted? &&
        !issuable.subscribed?(current_user, project)
    end
    command :subscribe do
      @updates[:subscription_event] = 'subscribe'
    end

    desc 'Unsubscribe'
    humanized do
      "Unsubscribes from this #{issuable.to_ability_name.humanize(capitalize: false)}."
    end
    condition do
      issuable.persisted? &&
        issuable.subscribed?(current_user, project)
    end
    command :unsubscribe do
      @updates[:subscription_event] = 'unsubscribe'
    end

    desc 'Set due date'
    humanized do |due_date_param|
      due_date = Chronic.parse(due_date_param).try(:to_date)
      "Sets the due date to #{due_date}." if due_date
    end
    params '<in 2 days | this Friday | December 31st>'
    condition do
      issuable.respond_to?(:due_date) &&
        current_user.can?(:"admin_#{issuable.to_ability_name}", project)
    end
    command :due do |due_date_param|
      due_date = Chronic.parse(due_date_param).try(:to_date)

      @updates[:due_date] = due_date if due_date
    end

    desc 'Remove due date'
    humanized 'Removes the due date.'
    condition do
      issuable.persisted? &&
        issuable.respond_to?(:due_date) &&
        issuable.due_date? &&
        current_user.can?(:"admin_#{issuable.to_ability_name}", project)
    end
    command :remove_due_date do
      @updates[:due_date] = nil
    end

    desc 'Toggle the Work In Progress status'
    humanized 'Toggles the Work In Progress status.'
    condition do
      issuable.persisted? &&
        issuable.respond_to?(:work_in_progress?) &&
        current_user.can?(:"update_#{issuable.to_ability_name}", issuable)
    end
    command :wip do
      @updates[:wip_event] = issuable.work_in_progress? ? 'unwip' : 'wip'
    end

    desc 'Toggle emoji award'
    humanized 'Toggles XXXXX emoji award.'
    params ':emoji:'
    condition do
      issuable.persisted?
    end
    command :award do |emoji|
      name = award_emoji_name(emoji)
      if name && issuable.user_can_award?(current_user, name)
        @updates[:emoji_award] = name
      end
    end

    desc 'Set time estimate'
    humanized 'Sets time estimate.'
    params '<1w 3d 2h 14m>'
    condition do
      current_user.can?(:"admin_#{issuable.to_ability_name}", project)
    end
    command :estimate do |raw_duration|
      time_estimate = Gitlab::TimeTrackingFormatter.parse(raw_duration)

      if time_estimate
        @updates[:time_estimate] = time_estimate
      end
    end

    desc 'Add or substract spent time'
    humanized 'Adds / substracts XXXXX time.'
    params '<1h 30m | -1h 30m>'
    condition do
      current_user.can?(:"admin_#{issuable.to_ability_name}", issuable)
    end
    command :spend do |raw_duration|
      time_spent = Gitlab::TimeTrackingFormatter.parse(raw_duration)

      if time_spent
        @updates[:spend_time] = { duration: time_spent, user: current_user }
      end
    end

    desc 'Remove time estimate'
    humanized 'Removes time estimate.'
    condition do
      issuable.persisted? &&
        current_user.can?(:"admin_#{issuable.to_ability_name}", project)
    end
    command :remove_estimate do
      @updates[:time_estimate] = 0
    end

    desc 'Remove spent time'
    humanized 'Removes spent time.'
    condition do
      issuable.persisted? &&
        current_user.can?(:"admin_#{issuable.to_ability_name}", project)
    end
    command :remove_time_spent do
      @updates[:spend_time] = { duration: :reset, user: current_user }
    end

    # This is a dummy command, so that it appears in the autocomplete commands
    desc 'CC'
    params '@user'
    command :cc

    desc 'Define target branch for MR'
    humanized 'Sets target branch to XXXXX'
    params '<Local branch name>'
    condition do
      issuable.respond_to?(:target_branch) &&
        (current_user.can?(:"update_#{issuable.to_ability_name}", issuable) ||
          issuable.new_record?)
    end
    command :target_branch do |target_branch_param|
      branch_name = target_branch_param.strip
      @updates[:target_branch] = branch_name if project.repository.branch_names.include?(branch_name)
    end

    def find_labels(labels_param)
      extract_references(labels_param, :label)
    end

    def find_label_references(labels_param)
      find_labels(labels_param).map(&:to_reference)
    end

    def find_label_ids(labels_param)
      find_labels(labels_param).map(&:id)
    end

    def humanize_commands(commands, opts)
      commands.map do |name, arg|
        definition = self.class.command_definitions_by_name[name.to_sym]
        next unless definition

        definition.humanize(self, opts, arg)
      end.compact
    end

    def extract_updates(commands, opts)
      commands.each do |name, arg|
        definition = self.class.command_definitions_by_name[name.to_sym]
        next unless definition

        definition.execute(self, opts, arg)
      end
    end

    def extract_references(arg, type)
      ext = Gitlab::ReferenceExtractor.new(project, current_user)
      ext.analyze(arg, author: current_user)

      ext.references(type)
    end

    def award_emoji_name(emoji)
      match = emoji.match(Banzai::Filter::EmojiFilter.emoji_pattern)
      match[1] if match
    end
  end
end
