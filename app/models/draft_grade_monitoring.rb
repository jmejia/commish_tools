# Monitoring and instrumentation for draft grade calculations
# Provides metrics and error tracking for performance monitoring
module DraftGradeMonitoring
  extend ActiveSupport::Concern

  included do
    # Track calculation time
    around_create :track_creation_time
    around_update :track_update_time

    # Log errors
    after_rollback :log_rollback_error
  end

  class_methods do
    def calculate_with_monitoring(draft)
      start_time = Time.current

      ActiveSupport::Notifications.instrument('draft_grade.calculation_started', draft_id: draft.id) do
        result = yield

        duration = Time.current - start_time
        ActiveSupport::Notifications.instrument('draft_grade.calculation_completed',
          draft_id: draft.id,
          duration: duration,
          grade_count: draft.draft_grades.count
        )

        Rails.logger.info(
          event: 'draft_grades_calculated',
          draft_id: draft.id,
          league_id: draft.league_id,
          duration_seconds: duration,
          grades_count: draft.draft_grades.count
        )

        result
      end
    rescue => e
      ActiveSupport::Notifications.instrument('draft_grade.calculation_failed',
        draft_id: draft.id,
        error: e.class.name,
        message: e.message
      )

      Rails.logger.error(
        event: 'draft_grades_calculation_failed',
        draft_id: draft.id,
        error_class: e.class.name,
        error_message: e.message,
        backtrace: e.backtrace.first(5)
      )

      raise
    end
  end

  private

  def track_creation_time
    start_time = Time.current
    yield
    duration = Time.current - start_time

    Rails.logger.info(
      event: 'draft_grade_created',
      draft_grade_id: id,
      user_id: user_id,
      league_id: league_id,
      grade: grade,
      duration_ms: (duration * 1000).round
    )
  end

  def track_update_time
    start_time = Time.current
    yield
    duration = Time.current - start_time

    Rails.logger.info(
      event: 'draft_grade_updated',
      draft_grade_id: id,
      changes: saved_changes.keys,
      duration_ms: (duration * 1000).round
    )
  end

  def log_rollback_error
    Rails.logger.error(
      event: 'draft_grade_rollback',
      draft_grade_id: id,
      errors: errors.full_messages,
      attributes: attributes
    )
  end
end

# Monitoring for draft import operations
module DraftImportMonitoring
  def import_with_monitoring
    start_time = Time.current
    picks_count = 0

    begin
      result = yield
      picks_count = result.draft_picks.count if result.respond_to?(:draft_picks)

      duration = Time.current - start_time
      Rails.logger.info(
        event: 'draft_import_completed',
        league_id: league.id,
        draft_id: result&.id,
        picks_imported: picks_count,
        duration_seconds: duration
      )

      result
    rescue => e
      Rails.logger.error(
        event: 'draft_import_failed',
        league_id: league.id,
        error_class: e.class.name,
        error_message: e.message,
        duration_seconds: Time.current - start_time
      )
      raise
    end
  end
end