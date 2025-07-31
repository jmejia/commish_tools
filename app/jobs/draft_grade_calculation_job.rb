# Background job for calculating draft grades asynchronously
# Prevents timeouts and improves user experience for large drafts
class DraftGradeCalculationJob < ApplicationJob
  queue_as :default

  # Retry with exponential backoff if external API fails
  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(draft)
    Rails.logger.info "Calculating grades for draft #{draft.id} in league #{draft.league.name}"

    analysis = DraftAnalysis.new(draft)
    analysis.calculate_all_grades

    # Notify league owner when complete (future feature)
    # DraftGradeMailer.grades_ready(draft).deliver_later

    Rails.logger.info "Successfully calculated grades for draft #{draft.id}"
  rescue => e
    Rails.logger.error "Failed to calculate grades for draft #{draft.id}: #{e.message}"
    raise # Re-raise to trigger retry
  end
end