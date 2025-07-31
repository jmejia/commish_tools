require 'rails_helper'

RSpec.describe DraftPick, type: :model do
  let(:pick_data) do
    {
      'round' => 2,
      'pick_no' => 5,
      'player_id' => 'player123',
      'picked_by' => 'user456'
    }
  end

  let(:player_projection) do
    {
      name: 'Justin Jefferson',
      position: 'WR',
      projected_points: 280,
      replacement_level: 90
    }
  end

  let(:adp_data) do
    {
      'player123' => { adp: 15.5 }
    }
  end

  subject(:draft_pick) do
    described_class.new(
      pick_data: pick_data,
      player_projection: player_projection,
      adp_data: adp_data
    )
  end

  describe '#initialize' do
    it 'sets attributes from pick data' do
      expect(draft_pick.round).to eq(2)
      expect(draft_pick.pick_number).to eq(5)
      expect(draft_pick.player_id).to eq('player123')
      expect(draft_pick.picked_by_user_id).to eq('user456')
    end

    it 'sets attributes from player projection' do
      expect(draft_pick.player_name).to eq('Justin Jefferson')
      expect(draft_pick.position).to eq('WR')
      expect(draft_pick.projected_points).to eq(280)
      expect(draft_pick.replacement_level_points).to eq(90)
    end

    it 'sets ADP from adp_data' do
      expect(draft_pick.adp).to eq(15.5)
    end
  end

  describe '#overall_pick' do
    it 'calculates overall pick number correctly' do
      expect(draft_pick.overall_pick).to eq(17) # (2-1)*12 + 5
    end
  end

  describe '#value_over_replacement' do
    it 'calculates VOR correctly' do
      expect(draft_pick.value_over_replacement).to eq(190) # 280 - 90
    end

    context 'without projections' do
      let(:player_projection) { nil }
      
      it 'returns 0' do
        expect(draft_pick.value_over_replacement).to eq(0)
      end
    end
  end

  describe '#reach_value' do
    it 'calculates reach value correctly' do
      expect(draft_pick.reach_value).to eq(1.5) # 17 - 15.5
    end

    context 'without ADP data' do
      let(:adp_data) { {} }
      
      it 'returns nil' do
        expect(draft_pick.reach_value).to be_nil
      end
    end
  end

  describe '#is_reach?' do
    context 'when picked much earlier than ADP' do
      let(:adp_data) { { 'player123' => { adp: 30 } } }
      
      it 'returns true' do
        expect(draft_pick.is_reach?).to be true
      end
    end

    context 'when picked at fair value' do
      it 'returns false' do
        expect(draft_pick.is_reach?).to be false
      end
    end
  end

  describe '#is_value?' do
    context 'when picked much later than ADP' do
      let(:adp_data) { { 'player123' => { adp: 3 } } }
      
      it 'returns true' do
        expect(draft_pick.is_value?).to be true
      end
    end

    context 'when picked at fair value' do
      it 'returns false' do
        expect(draft_pick.is_value?).to be false
      end
    end
  end

  describe '#pick_quality' do
    it 'categorizes picks correctly' do
      allow(draft_pick).to receive(:reach_value).and_return(-20)
      expect(draft_pick.pick_quality).to eq('massive_reach')

      allow(draft_pick).to receive(:reach_value).and_return(-10)
      expect(draft_pick.pick_quality).to eq('reach')

      allow(draft_pick).to receive(:reach_value).and_return(0)
      expect(draft_pick.pick_quality).to eq('fair_value')

      allow(draft_pick).to receive(:reach_value).and_return(15)
      expect(draft_pick.pick_quality).to eq('good_value')

      allow(draft_pick).to receive(:reach_value).and_return(25)
      expect(draft_pick.pick_quality).to eq('steal')
    end
  end

  describe '#points_per_draft_capital' do
    it 'calculates efficiency correctly' do
      expect(draft_pick.points_per_draft_capital.to_f).to be_within(0.01).of(16.47) # 280 / 17
    end

    context 'without projections' do
      let(:player_projection) { nil }
      
      it 'returns 0' do
        expect(draft_pick.points_per_draft_capital).to eq(0)
      end
    end
  end
end