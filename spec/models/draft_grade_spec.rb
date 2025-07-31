require 'rails_helper'

RSpec.describe DraftGrade, type: :model do
  describe 'associations' do
    it { should belong_to(:league) }
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it { should validate_presence_of(:grade) }
    it { should validate_inclusion_of(:grade).in_array(%w[A+ A A- B+ B B- C+ C C- D+ D D- F]) }
    it { should validate_presence_of(:projected_rank) }
    it { should validate_numericality_of(:projected_rank).is_greater_than(0).is_less_than_or_equal_to(20) }
    
    describe 'uniqueness' do
      let(:league) { create(:league) }
      let(:user) { create(:user) }
      let!(:existing_grade) { create(:draft_grade, league: league, user: user) }
      
      it 'validates uniqueness of user_id scoped to league_id' do
        duplicate_grade = build(:draft_grade, league: league, user: user)
        expect(duplicate_grade).not_to be_valid
        expect(duplicate_grade.errors[:user_id]).to include("can only have one draft grade per league")
      end
    end
  end

  describe '#letter_grade_value' do
    it 'returns correct numeric values for grades' do
      grade = build(:draft_grade, grade: 'A+')
      expect(grade.letter_grade_value).to eq(4.3)
      
      grade.grade = 'B'
      expect(grade.letter_grade_value).to eq(3.0)
      
      grade.grade = 'F'
      expect(grade.letter_grade_value).to eq(0.0)
    end
  end

  describe '#grade_color_class' do
    it 'returns correct color classes for grades' do
      grade = build(:draft_grade, grade: 'A')
      expect(grade.grade_color_class).to eq('text-green-600 bg-green-50')
      
      grade.grade = 'B+'
      expect(grade.grade_color_class).to eq('text-blue-600 bg-blue-50')
      
      grade.grade = 'F'
      expect(grade.grade_color_class).to eq('text-red-600 bg-red-50')
    end
  end

  describe '#team_name' do
    let(:user) { create(:user, first_name: 'John', last_name: 'Doe') }
    let(:league) { create(:league) }
    let(:grade) { create(:draft_grade, user: user, league: league) }
    
    context 'when user has a league membership with team name' do
      let!(:membership) { create(:league_membership, user: user, league: league, team_name: 'The Champions') }
      
      it 'returns the team name' do
        expect(grade.team_name).to eq('The Champions')
      end
    end
    
    context 'when user has no league membership' do
      it 'returns the user display name' do
        expect(grade.team_name).to eq(user.display_name)
      end
    end
  end
end