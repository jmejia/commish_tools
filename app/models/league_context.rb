class LeagueContext < ApplicationRecord
  belongs_to :league

  validates :league_id, uniqueness: true
  validates :nature, :tone, :rivalries, :history, :response_style, length: { maximum: 1000 }
  
  # JSON accessors for the structured content
  def nature
    content&.dig('nature') || ''
  end
  
  def nature=(value)
    self.content = (content || {}).merge('nature' => value.to_s)
  end
  
  def tone
    content&.dig('tone') || ''
  end
  
  def tone=(value)
    self.content = (content || {}).merge('tone' => value.to_s)
  end
  
  def rivalries
    content&.dig('rivalries') || ''
  end
  
  def rivalries=(value)
    self.content = (content || {}).merge('rivalries' => value.to_s)
  end
  
  def history
    content&.dig('history') || ''
  end
  
  def history=(value)
    self.content = (content || {}).merge('history' => value.to_s)
  end
  
  def response_style
    content&.dig('response_style') || ''
  end
  
  def response_style=(value)
    self.content = (content || {}).merge('response_style' => value.to_s)
  end
  
  # Method to get the structured content as a hash (for ChatGPT)
  def structured_content
    {
      nature: nature,
      tone: tone,
      rivalries: rivalries,
      history: history,
      response_style: response_style
    }
  end
  
  # Check if any fields have content
  def has_content?
    [nature, tone, rivalries, history, response_style].any?(&:present?)
  end
end