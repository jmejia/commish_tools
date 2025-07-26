class ChangeLeagueContextContentToJsonb < ActiveRecord::Migration[8.0]
  def up
    # Add a temporary column
    add_column :league_contexts, :content_json, :jsonb
    
    # Migrate existing data - convert text to a default structure
    LeagueContext.reset_column_information
    LeagueContext.find_each do |context|
      if context.content.present?
        # Put existing text content into the 'history' field as it's most likely to contain general context
        structured_content = {
          nature: "",
          tone: "",
          rivalries: "",
          history: context.content,
          response_style: ""
        }
        context.update_column(:content_json, structured_content)
      end
    end
    
    # Drop the old column and rename the new one
    remove_column :league_contexts, :content
    rename_column :league_contexts, :content_json, :content
  end
  
  def down
    # Add back the text column
    add_column :league_contexts, :content_text, :text
    
    # Convert JSON back to text (just take the history field)
    LeagueContext.reset_column_information
    LeagueContext.find_each do |context|
      if context.content.present?
        text_content = context.content['history'] || context.content.values.select(&:present?).join('. ')
        context.update_column(:content_text, text_content)
      end
    end
    
    # Drop the JSON column and rename the text column
    remove_column :league_contexts, :content
    rename_column :league_contexts, :content_text, :content
  end
end