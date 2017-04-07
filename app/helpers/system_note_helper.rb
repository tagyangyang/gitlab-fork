module SystemNoteHelper
  ICON_NAMES_BY_ACTION = {
    'commit' => 'icon_commit',
    'merge' => 'icon_merge',
    'merged' => 'icon_merged',
    'opened' => 'icon_status_open',
    'closed' => 'icon_status_closed',
    'time_tracking' => 'icon_stopwatch',
    'assignee' => 'icon_user',
    'title' => 'icon_pencil',
    'task' => 'icon_check_square_o',
    'label' => 'icon_tags',
    'cross_reference' => 'icon_random',
    'branch' => 'icon_code_fork',
    'confidential' => 'icon_eye_slash',
    'visible' => 'icon_eye',
    'milestone' => 'icon_clock_o',
    'discussion' => 'icon_comment_o',
    'moved' => 'icon_arrow_circle_o_right'
  }.freeze

  def icon_for_system_note(note)
    icon_name = ICON_NAMES_BY_ACTION[note.system_note_metadata&.action]
    custom_icon(icon_name) if icon_name
  end
end
