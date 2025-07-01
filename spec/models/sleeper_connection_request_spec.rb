require 'rails_helper'

RSpec.describe SleeperConnectionRequest, type: :model do
  let(:user) { create(:user) }
  let(:reviewer) { create(:user) }
  let(:sleeper_request) { create(:sleeper_connection_request, user: user) }

  describe 'associations' do
    it 'belongs to user' do
      expect(sleeper_request.user).to eq(user)
      expect(sleeper_request).to respond_to(:user)
    end

    it 'optionally belongs to reviewed_by user' do
      expect(sleeper_request).to respond_to(:reviewed_by)
      expect(sleeper_request.reviewed_by).to be_nil

      sleeper_request.update!(reviewed_by: reviewer)
      expect(sleeper_request.reviewed_by).to eq(reviewer)
    end
  end

  describe 'validations' do
    it 'validates presence of sleeper_username' do
      sleeper_request.sleeper_username = nil
      expect(sleeper_request).not_to be_valid
      expect(sleeper_request.errors[:sleeper_username]).to include("can't be blank")
    end

    it 'validates presence of sleeper_id' do
      sleeper_request.sleeper_id = nil
      expect(sleeper_request).not_to be_valid
      expect(sleeper_request.errors[:sleeper_id]).to include("can't be blank")
    end

    it 'validates presence of requested_at' do
      sleeper_request.requested_at = nil
      expect(sleeper_request).not_to be_valid
      expect(sleeper_request.errors[:requested_at]).to include("can't be blank")
    end
  end

  describe 'enums' do
    it 'defines status enum correctly' do
      expect(SleeperConnectionRequest.statuses).to eq({
        'pending' => 0,
        'approved' => 1,
        'rejected' => 2,
      })
    end

    it 'defaults to pending status' do
      new_request = build(:sleeper_connection_request)
      expect(new_request.status).to eq('pending')
    end

    it 'allows status transitions' do
      expect(sleeper_request.pending?).to be true

      sleeper_request.approved!
      expect(sleeper_request.approved?).to be true

      sleeper_request.rejected!
      expect(sleeper_request.rejected?).to be true
    end
  end

  describe 'scopes' do
    let!(:old_request) { create(:sleeper_connection_request, user: user, requested_at: 2.days.ago) }
    let!(:new_request) { create(:sleeper_connection_request, user: user, requested_at: 1.day.ago) }
    let!(:approved_request) do
      create(:sleeper_connection_request, user: user, status: :approved, requested_at: 3.days.ago)
    end

    describe '.recent' do
      it 'orders by requested_at desc' do
        results = SleeperConnectionRequest.recent
        expect(results.first).to eq(new_request)
        expect(results.last).to eq(approved_request)
      end
    end

    describe '.needs_review' do
      it 'returns pending requests ordered by requested_at asc' do
        results = SleeperConnectionRequest.needs_review
        expect(results).to include(old_request, new_request)
        expect(results).not_to include(approved_request)
        expect(results.first).to eq(old_request) # oldest first for review
      end
    end
  end

  describe '#approve!' do
    it 'updates status and sets review metadata' do
      expect do
        sleeper_request.approve!(reviewer)
      end.to change { sleeper_request.reload.status }.from('pending').to('approved').
        and change { sleeper_request.reviewed_at }.from(nil).
        and change { sleeper_request.reviewed_by }.from(nil).to(reviewer)

      expect(sleeper_request.reload.reviewed_at).to be_within(1.second).of(Time.current)
    end

    it 'updates user sleeper connection info' do
      sleeper_request.update!(sleeper_username: 'testuser', sleeper_id: '12345')

      expect do
        sleeper_request.approve!(reviewer)
      end.to change { user.reload.sleeper_username }.from(nil).to('testuser').
        and change { user.sleeper_id }.from(nil).to('12345')
    end

    it 'handles the transaction atomically' do
      sleeper_request.update!(sleeper_username: 'testuser', sleeper_id: '12345')

      # Stub user update to fail
      allow_any_instance_of(User).to receive(:update!).and_raise(ActiveRecord::RecordInvalid.new(user))

      expect do
        sleeper_request.approve!(reviewer)
      end.to raise_error(ActiveRecord::RecordInvalid)

      # Verify rollback - request should still be pending
      expect(sleeper_request.reload.status).to eq('pending')
      expect(sleeper_request.reviewed_at).to be_nil
    end
  end

  describe '#reject!' do
    it 'updates status and sets review metadata' do
      expect do
        sleeper_request.reject!(reviewer, 'Invalid username')
      end.to change { sleeper_request.reload.status }.from('pending').to('rejected').
        and change { sleeper_request.reviewed_at }.from(nil).
        and change { sleeper_request.reviewed_by }.from(nil).to(reviewer).
        and change { sleeper_request.rejection_reason }.from(nil).to('Invalid username')

      expect(sleeper_request.reload.reviewed_at).to be_within(1.second).of(Time.current)
    end

    it 'works without rejection reason' do
      expect do
        sleeper_request.reject!(reviewer)
      end.to change { sleeper_request.reload.status }.from('pending').to('rejected')

      expect(sleeper_request.rejection_reason).to be_nil
    end

    it 'does not update user sleeper connection info' do
      original_username = user.sleeper_username
      original_id = user.sleeper_id

      sleeper_request.reject!(reviewer, 'Test rejection')

      expect(user.reload.sleeper_username).to eq(original_username)
      expect(user.sleeper_id).to eq(original_id)
    end
  end
end
