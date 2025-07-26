require 'rails_helper'

RSpec.describe LeagueContext, type: :model do
  describe 'associations' do
    it { should belong_to(:league) }
  end

  describe 'validations' do
    subject { build(:league_context) }

    it { should validate_length_of(:nature).is_at_most(1000) }
    it { should validate_length_of(:tone).is_at_most(1000) }
    it { should validate_length_of(:rivalries).is_at_most(1000) }
    it { should validate_length_of(:history).is_at_most(1000) }
    it { should validate_length_of(:response_style).is_at_most(1000) }
    it { should validate_uniqueness_of(:league_id) }
  end

  describe 'factory' do
    it 'creates a valid league context' do
      league_context = build(:league_context)
      expect(league_context).to be_valid
    end
  end

  describe 'structured content accessors' do
    let(:league) { create(:league) }
    let(:league_context) { LeagueContext.new(league: league) }

    it 'sets and gets nature' do
      league_context.nature = "Competitive friends"
      expect(league_context.nature).to eq("Competitive friends")
    end

    it 'sets and gets tone' do
      league_context.tone = "Humorous but serious"
      expect(league_context.tone).to eq("Humorous but serious")
    end

    it 'sets and gets rivalries' do
      league_context.rivalries = "Team A vs Team B"
      expect(league_context.rivalries).to eq("Team A vs Team B")
    end

    it 'sets and gets history' do
      league_context.history = "5 year running league"
      expect(league_context.history).to eq("5 year running league")
    end

    it 'sets and gets response_style' do
      league_context.response_style = "Confident and witty"
      expect(league_context.response_style).to eq("Confident and witty")
    end

    it 'returns empty string for unset fields' do
      empty_context = LeagueContext.new(league: league)
      expect(empty_context.nature).to eq("")
      expect(empty_context.tone).to eq("")
      expect(empty_context.rivalries).to eq("")
      expect(empty_context.history).to eq("")
      expect(empty_context.response_style).to eq("")
    end
  end

  describe '#structured_content' do
    it 'returns a hash with all content fields' do
      league_context = build(:league_context)
      result = league_context.structured_content

      expect(result).to be_a(Hash)
      expect(result.keys).to eq([:nature, :tone, :rivalries, :history, :response_style])
      expect(result[:nature]).to eq(league_context.nature)
      expect(result[:tone]).to eq(league_context.tone)
      expect(result[:rivalries]).to eq(league_context.rivalries)
      expect(result[:history]).to eq(league_context.history)
      expect(result[:response_style]).to eq(league_context.response_style)
    end
  end

  describe '#has_content?' do
    let(:league) { create(:league) }

    it 'returns true when any field has content' do
      league_context = LeagueContext.new(league: league)
      league_context.nature = "Something"
      expect(league_context.has_content?).to be true
    end

    it 'returns false when all fields are empty' do
      league_context = LeagueContext.new(league: league)
      expect(league_context.has_content?).to be false
    end
  end

  describe 'field length validation' do
    let(:league) { create(:league) }

    it 'rejects fields that are too long' do
      league_context = LeagueContext.new(league: league)
      league_context.nature = 'A' * 1001

      expect(league_context).not_to be_valid
      expect(league_context.errors[:nature]).to include('is too long (maximum is 1000 characters)')
    end

    it 'allows fields at the maximum length' do
      league_context = LeagueContext.new(league: league)
      league_context.nature = 'A' * 1000

      expect(league_context).to be_valid
    end
  end

  describe 'uniqueness validation' do
    let(:league) { create(:league) }

    it 'allows only one context per league' do
      create(:league_context, league: league)

      duplicate_context = build(:league_context, league: league)
      expect(duplicate_context).not_to be_valid
      expect(duplicate_context.errors[:league_id]).to include('has already been taken')
    end

    it 'allows different leagues to have their own contexts' do
      league1 = create(:league)
      league2 = create(:league, sleeper_league_id: 'different_id')

      context1 = create(:league_context, league: league1)
      context2 = build(:league_context, league: league2)

      expect(context1).to be_valid
      expect(context2).to be_valid
    end
  end
end
