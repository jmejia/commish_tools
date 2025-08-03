# Domain object for interacting with Sleeper API draft data
# Handles fetching and importing draft information from Sleeper
class SleeperDraft
  include DraftImportMonitoring

  attr_reader :league

  def initialize(league)
    @league = league
  end

  def import_and_calculate_grades
    import_with_monitoring do
      sleeper_draft_data = fetch_completed_draft
      return unless sleeper_draft_data

      picks_data = fetch_picks_data(sleeper_draft_data)
      analysis = DraftAnalysis.new(league, picks_data)
      analysis.calculate_all_grades

      true
    end
  end

  private

  def fetch_completed_draft
    drafts = client.league_drafts(league.sleeper_league_id)

    drafts&.find { |d| d.status == 'complete' }
  end

  def client
    @client ||= SleeperFF.new
  end

  def fetch_picks_data(sleeper_draft_data)
    picks = client.draft_picks(sleeper_draft_data.draft_id)

    {
      'draft_id' => sleeper_draft_data.draft_id,
      'draft' => picks,
      'settings' => sleeper_draft_data.settings,
      'league_size' => sleeper_draft_data.settings['teams'] || league.league_size || 12,
    }
  end
end
