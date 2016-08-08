class MattermostService < Service
  boolean_accessor :notify_only_broken_builds
  prop_accessor :webhook, :username, :channel

  validates :webhook, presence: true, url: true, if: :activated?

  def initialize_properties
    # Custom serialized properties initialization
    self.supported_events.each { |event| self.class.prop_accessor(event_channel_name(event)) }

    if properties.nil?
      self.properties = {}
      self.notify_only_broken_builds = true
    end
  end

  def title
    'Mattermost'
  end

  def description
    'Self-hosted Slack-alternative'
  end

  def help
    'This service sends notifications to your Mattermost instance.<br/>
    To setup this Service you need to create a new <b>"Incoming webhook"</b> on the Mattermost integrations panel,
    and enter the Webhook URL below. You can override the Channels if needed.'
  end

  def to_param
    'mattermost'
  end

  def fields
    default_fields =
      [
        { type: 'text', name: 'webhook',   placeholder: 'http://mattermost.company.com/hooks/...' },
        { type: 'text', name: 'username', placeholder: 'GitLab' },
        { type: 'text', name: 'channel', placeholder: "town-square" },
        { type: 'checkbox', name: 'notify_only_broken_builds' },
      ]

    default_fields + build_event_channels
  end

  def supported_events
    %w(push issue merge_request note tag_push build wiki_page)
  end

  def execute(data)
    return unless webhook.present?

    data = data.with_indifferent_access
    return unless supported_events.include?(data[:object_kind])

    message = message(data)
    return unless message

    message.send(webhook, channel: channel, username: username || 'GitLab')
  end

  def event_channel_names
    supported_events.map { |event| event_channel_name(event) }
  end

  def event_field(event)
    fields.find { |field| field[:name] == event_channel_name(event) }
  end

  def global_fields
    fields.reject { |field| field[:name].end_with?('channel') }
  end

  private

  def get_channel_field(event)
    field_name = event_channel_name(event)
    self.public_send(field_name)
  end

  def build_event_channels
    supported_events.reduce([]) do |channels, event|
      channels << { type: 'text', name: event_channel_name(event), placeholder: "town-square" }
    end
  end

  def event_channel_name(event)
    "#{event}_channel"
  end

  def message(data)
    case data[:object_kind]
    when "push", "tag_push"
      PushMessage.new(data)
    when "issue"
      IssueMessage.new(data) unless is_update?(data)
    when "merge_request"
      MergeMessage.new(data) unless is_update?(data)
    when "note"
      NoteMessage.new(data)
    when "build"
      BuildMessage.new(data) if should_build_be_notified?(data)
    when "wiki_page"
      WikiPageMessage.new(data)
    end
  end

  def is_update?(data)
    data[:object_attributes][:action] == 'update'
  end

  def should_build_be_notified?(data)
    case data[:commit][:status]
    when 'success'
      !notify_only_broken_builds?
    when 'failed'
      true
    else
      false
    end
  end
end

require "mattermost_service/issue_message"
require "mattermost_service/push_message"
require "mattermost_service/merge_message"
require "mattermost_service/note_message"
require "mattermost_service/build_message"
require "mattermost_service/wiki_page_message"
