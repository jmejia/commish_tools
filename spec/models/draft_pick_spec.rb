require 'rails_helper'

RSpec.describe DraftPick, type: :model do
  let(:league) { create(:league) }
  let(:draft) { create(:draft, league: league) }
  let(:user) { create(:user) }

  let(:draft_pick) do
    create(:draft_pick,
      draft: draft,
      user: user,
      sleeper_player_id: 'player123',
      sleeper_user_id: 'user456',
      round: 2,
      pick_number: 5,
      overall_pick: 17, # (2-1)*12 + 5
      player_name: 'Justin Jefferson',
      position: 'WR',
      projected_points: 280,
      value_over_replacement: 190, # 280 - 90
      adp: 15.5)
  end

  subject { draft_pick }

  describe 'attributes' do
    it 'has correct pick data attributes' do
      expect(draft_pick.round).to eq(2)
      expect(draft_pick.pick_number).to eq(5)
      expect(draft_pick.sleeper_player_id).to eq('player123')
      expect(draft_pick.sleeper_user_id).to eq('user456')
    end

    it 'has correct player projection attributes' do
      expect(draft_pick.player_name).to eq('Justin Jefferson')
      expect(draft_pick.position).to eq('WR')
      expect(draft_pick.projected_points).to eq(280)
      expect(draft_pick.value_over_replacement).to eq(190)
    end

    it 'has correct ADP data' do
      expect(draft_pick.adp).to eq(15.5)
    end
  end

  describe '#overall_pick' do
    it 'has the correct overall pick number' do
      expect(draft_pick.overall_pick).to eq(17) # (2-1)*12 + 5
    end
  end

  describe '#value_over_replacement' do
    it 'has correct VOR value' do
      expect(draft_pick.value_over_replacement).to eq(190) # 280 - 90
    end

    context 'without projections' do
      let(:draft_pick_no_proj) do
        create(:draft_pick,
          draft: draft,
          user: user,
          projected_points: nil,
          value_over_replacement: nil)
      end

      it 'can have nil VOR' do
        expect(draft_pick_no_proj.value_over_replacement).to be_nil
      end
    end
  end

  describe '#reach_value' do
    it 'calculates reach value correctly' do
      expect(draft_pick.reach_value).to eq(1.5) # 17 - 15.5
    end

    context 'without ADP data' do
      let(:draft_pick_no_adp) do
        create(:draft_pick,
          draft: draft,
          user: user,
          overall_pick: 17,
          adp: nil)
      end

      it 'returns nil' do
        expect(draft_pick_no_adp.reach_value).to be_nil
      end
    end
  end

  describe '#is_reach?' do
    context 'when picked much earlier than ADP' do
      let(:reach_pick) do
        create(:draft_pick,
          draft: draft,
          user: user,
          overall_pick: 17,
          adp: 30.0) # picked at 17, ADP is 30, reach_value = -13, which is < -8 (REACH_THRESHOLD)
      end

      it 'returns true' do
        expect(reach_pick.is_reach?).to be true
      end
    end

    context 'when picked at fair value' do
      it 'returns false' do
        expect(draft_pick.is_reach?).to be false # reach_value = 1.5, which is > -8
      end
    end
  end

  describe '#is_value?' do
    context 'when picked much later than ADP' do
      let(:value_pick) do
        create(:draft_pick,
          draft: draft,
          user: user,
          overall_pick: 30,
          adp: 3.0) # picked at 30, ADP is 3, reach_value = 27, which is > 12 (VALUE_THRESHOLD)
      end

      it 'returns true' do
        expect(value_pick.is_value?).to be true
      end
    end

    context 'when picked at fair value' do
      it 'returns false' do
        expect(draft_pick.is_value?).to be false # reach_value = 1.5, which is < 12
      end
    end
  end

  describe '#pick_quality' do
    it 'categorizes picks correctly' do
      # massive_reach: reach_value < -15
      massive_reach_pick = create(:draft_pick, draft: draft, user: user, overall_pick: 5, adp: 30.0)
      expect(massive_reach_pick.pick_quality).to eq('massive_reach')

      # reach: -15 <= reach_value < -8
      reach_pick = create(:draft_pick, draft: draft, user: user, overall_pick: 10, adp: 20.0)
      expect(reach_pick.pick_quality).to eq('reach')

      # fair_value: -8 <= reach_value < 8
      fair_pick = create(:draft_pick, draft: draft, user: user, overall_pick: 15, adp: 15.0)
      expect(fair_pick.pick_quality).to eq('fair_value')

      # good_value: 8 <= reach_value < 20
      good_value_pick = create(:draft_pick, draft: draft, user: user, overall_pick: 25, adp: 10.0)
      expect(good_value_pick.pick_quality).to eq('good_value')

      # steal: reach_value >= 20
      steal_pick = create(:draft_pick, draft: draft, user: user, overall_pick: 30, adp: 5.0)
      expect(steal_pick.pick_quality).to eq('steal')
    end
  end

  describe '#points_per_draft_capital' do
    it 'calculates efficiency correctly' do
      expect(draft_pick.points_per_draft_capital.to_f).to be_within(0.01).of(16.47) # 280 / 17
    end

    context 'without projections' do
      let(:draft_pick_no_points) do
        create(:draft_pick,
          draft: draft,
          user: user,
          overall_pick: 17,
          projected_points: nil)
      end

      it 'returns 0' do
        expect(draft_pick_no_points.points_per_draft_capital).to eq(0)
      end
    end
  end
end
