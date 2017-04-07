require "spec_helper"

shared_examples "migrating a deleted user's associated records to the ghost user" do |record_class|
  record_class_name = record_class.to_s.titleize.downcase

  let(:project) { create(:project) }

  before do
    project.add_developer(user)
  end

  context "for a #{record_class_name} the user has created" do
    let!(:record) { created_record }

    it "does not delete the #{record_class_name}" do
      service.execute

      expect(record_class.find_by_id(record.id)).to be_present
    end

    it "migrates the #{record_class_name} so that the 'Ghost User' is the #{record_class_name} owner" do
      service.execute

      migrated_record = record_class.find_by_id(record.id)

      if migrated_record.respond_to?(:author)
        expect(migrated_record.author).to eq(User.ghost)
      else
        expect(migrated_record.send(author_alias)).to eq(User.ghost)
      end
    end

    it "blocks the user before migrating #{record_class_name}s to the 'Ghost User'" do
      service.execute

      expect(user).to be_blocked
    end
  end
end
