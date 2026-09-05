# frozen_string_literal: true

require_relative '../../db/migrate/20260831000000_purge_soft_deleted_images'

RSpec.describe PurgeSoftDeletedImages, type: :migration do
  include FileHelper

  subject(:migration) { described_class.new }

  let(:attachment) { white_logo_file }

  # RemoveDeletedAtFromAssets drops this column right after the migration under test
  # runs, so the current schema no longer has it. Recreate it for the duration of the
  # example to exercise the migration against the schema it was written for.
  around do |example|
    connection = ActiveRecord::Base.connection
    connection.add_column(:spree_assets, :deleted_at, :datetime)
    described_class::Asset.reset_column_information
    Spree::Asset.reset_column_information

    example.run
  ensure
    connection.remove_column(:spree_assets, :deleted_at)
    described_class::Asset.reset_column_information
    Spree::Asset.reset_column_information
  end

  # Spree::Image no longer soft-deletes, so mark the row directly to recreate the
  # state this migration has to clean up.
  def soft_delete(image)
    described_class::Asset.where(id: image.id).update_all(deleted_at: Time.zone.now)
  end

  describe '#up' do
    it "removes soft-deleted images and purges their blobs" do
      image = Spree::Image.create!(attachment:, viewable: create(:product))
      blob_id = image.attachment.blob_id
      attachment_id = image.attachment.id
      soft_delete(image)

      expect { migration.up }
        .to change { described_class::Asset.where.not(deleted_at: nil).count }
        .from(1).to(0)
        .and enqueue_job(ActiveStorage::PurgeJob)

      perform_enqueued_jobs

      expect(ActiveStorage::Attachment.find_by(id: attachment_id)).to be_nil
      expect(ActiveStorage::Blob.find_by(id: blob_id)).to be_nil
    end

    it "leaves live images untouched" do
      image = Spree::Image.create!(attachment:, viewable: create(:product))

      expect { migration.up }.not_to change { Spree::Image.count }

      expect(image.reload.attachment).to be_attached
    end

    it "keeps a blob that another attachment still references" do
      image = Spree::Image.create!(attachment:, viewable: create(:product))
      blob_id = image.attachment.blob_id

      other_image = Spree::Image.create!(attachment:, viewable: create(:product))
      other_image.attachment.attach(ActiveStorage::Blob.find(blob_id))

      soft_delete(image)

      migration.up
      perform_enqueued_jobs

      expect(ActiveStorage::Blob.find_by(id: blob_id)).to be_present
      expect(other_image.reload.attachment).to be_attached
    end

    it "purges an orphaned blob while sparing a shared one in the same batch" do
      shared_blob_image = Spree::Image.create!(attachment:, viewable: create(:product))
      shared_blob_id = shared_blob_image.attachment.blob_id

      live_image = Spree::Image.create!(attachment:, viewable: create(:product))
      live_image.attachment.attach(ActiveStorage::Blob.find(shared_blob_id))

      orphan_blob_image = Spree::Image.create!(attachment:, viewable: create(:product))
      orphan_blob_id = orphan_blob_image.attachment.blob_id

      soft_delete(shared_blob_image)
      soft_delete(orphan_blob_image)

      migration.up
      perform_enqueued_jobs

      expect(ActiveStorage::Blob.find_by(id: shared_blob_id)).to be_present
      expect(ActiveStorage::Blob.find_by(id: orphan_blob_id)).to be_nil
      expect(live_image.reload.attachment).to be_attached
    end

    it "removes a soft-deleted image that has no attachment" do
      image = Spree::Image.create!(attachment:, viewable: create(:product))
      image.attachment.detach
      soft_delete(image)

      expect { migration.up }
        .to change { described_class::Asset.where(id: image.id).count }.from(1).to(0)
    end

    context "when a batch fails to purge" do
      let!(:image) { Spree::Image.create!(attachment:, viewable: create(:product)) }

      before do
        soft_delete(image)
        allow(migration).to receive(:purge_batch).and_raise("boom")
      end

      it "re-raises after the loop, naming the failed batch, and preserves deleted_at" do
        expect { migration.up }
          .to raise_error(/PurgeSoftDeletedImages failed for 1 batch/)

        # The row and its deleted_at survive so the (idempotent) purge can be re-run.
        row = described_class::Asset.find_by(id: image.id)
        expect(row).to be_present
        expect(row.deleted_at).to be_present
      end
    end

    context "when the asset delete fails mid-batch" do
      let!(:image) { Spree::Image.create!(attachment:, viewable: create(:product)) }
      let(:attachment_id) { image.attachment.id }

      before do
        soft_delete(image)
        # Blow up after the attachment delete but before the asset delete commits, so
        # the whole transaction has to roll back.
        allow(described_class::Asset).to receive(:where).and_call_original
        allow(described_class::Asset).to receive(:where)
          .with(id: [image.id]).and_raise("asset delete failed")
      end

      it "rolls back the attachment delete so the attachment row survives" do
        expect do
          migration.up
        rescue StandardError
          nil
        end.not_to change { described_class::Attachment.where(id: attachment_id).count }

        expect(described_class::Attachment.find_by(id: attachment_id)).to be_present
      end

      it "does not enqueue an ActiveStorage::PurgeJob" do
        expect do
          migration.up
        rescue StandardError
          nil
        end.not_to enqueue_job(ActiveStorage::PurgeJob)
      end
    end
  end

  describe '#down' do
    it "is irreversible, since the purged images and blobs are gone for good" do
      expect { migration.down }.to raise_error ActiveRecord::IrreversibleMigration
    end
  end
end
