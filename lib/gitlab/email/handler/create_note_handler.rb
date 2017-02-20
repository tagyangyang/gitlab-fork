
require 'gitlab/email/handler/base_handler'
require 'gitlab/email/handler/reply_processing'

module Gitlab
  module Email
    module Handler
      class CreateNoteHandler < BaseHandler
        include ReplyProcessing

        def can_handle?
          mail_key =~ /\A\w+\z/
        end

        def execute
          raise SentNotificationNotFoundError unless sent_notification
          raise AutoGeneratedEmailError if mail.header.to_s =~ /auto-(generated|replied)/

          validate_permission!(:create_note)

          raise NoteableNotFoundError unless sent_notification.noteable
          raise EmptyEmailError if message.blank?

          verify_record!(
            record: create_note,
            invalid_exception: InvalidNoteError,
            record_name: 'comment')
        end

        private

        def author
          sent_notification.recipient
        end

        def project
          sent_notification.project
        end

        def sent_notification
          @sent_notification ||= SentNotification.for(mail_key)
        end

        def create_note
          Notes::CreateService.new(
            project,
            author,
            note:           message,
            noteable_type:  sent_notification.noteable_type,
            noteable_id:    sent_notification.noteable_id,
            commit_id:      sent_notification.commit_id,
            line_code:      sent_notification.line_code,
            position:       sent_notification.position,
            type:           sent_notification.note_type
          ).execute
        end
      end
    end
  end
end
