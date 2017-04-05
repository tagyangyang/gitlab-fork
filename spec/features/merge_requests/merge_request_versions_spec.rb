require 'spec_helper'

feature 'Merge Request versions', js: true, feature: true do
  let(:merge_request) { create(:merge_request, importing: true) }
  let(:project) { merge_request.source_project }
  let!(:merge_request_diff1) { merge_request.merge_request_diffs.create(head_commit_sha: '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9') }
  let!(:merge_request_diff2) { merge_request.merge_request_diffs.create(head_commit_sha: nil) }
  let!(:merge_request_diff3) { merge_request.merge_request_diffs.create(head_commit_sha: '5937ac0a7beb003549fc5fd26fc247adbce4a52e') }

  before do
    login_as :admin
    visit diffs_namespace_project_merge_request_path(project.namespace, project, merge_request)
  end

  it 'show the latest version of the diff' do
    page.within '.mr-version-dropdown' do
      expect(page).to have_content 'latest version'
    end

    expect(page).to have_content '8 changed files'
  end

  describe 'switch between versions' do
    before do
      page.within '.mr-version-dropdown' do
        find('.btn-default').click
        find(:link, 'version 1').trigger('click')
      end
    end

    it 'should show older version' do
      page.within '.mr-version-dropdown' do
        expect(page).to have_content 'version 1'
      end

      expect(page).to have_content '5 changed files'
    end

    it 'show the message about disabled comments' do
      expect(page).to have_content 'Comments are disabled'
    end
  end

  describe 'compare with older version' do
    before do
      page.within '.mr-version-compare-dropdown' do
        find('.btn-default').click
        find(:link, 'version 1').trigger('click')
      end
    end

    it 'has a path with comparison context' do
      expect(page).to have_current_path diffs_namespace_project_merge_request_path(
        project.namespace,
        project,
        merge_request.iid,
        diff_id: merge_request_diff3.id,
        start_sha: '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9'
      )
    end

    it 'should have correct value in the compare dropdown' do
      page.within '.mr-version-compare-dropdown' do
        expect(page).to have_content 'version 1'
      end
    end

    it 'show the message about disabled comments' do
      expect(page).to have_content 'Comments are disabled'
    end

    it 'show diff between new and old version' do
      expect(page).to have_content '4 changed files with 15 additions and 6 deletions'
    end

    it 'should return to latest version when "Show latest version" button is clicked' do
      click_link 'Show latest version'
      page.within '.mr-version-dropdown' do
        expect(page).to have_content 'latest version'
      end
      expect(page).to have_content '8 changed files'
    end
  end

  describe 'compare with same version' do
    before do
      page.within '.mr-version-compare-dropdown' do
        find('.btn-default').click
        click_link 'version 1'
      end
    end

    it 'should have 0 chages between versions' do
      page.within '.mr-version-compare-dropdown' do
        expect(find('.dropdown-toggle')).to have_content 'version 1'
      end

      page.within '.mr-version-dropdown' do
        find('.btn-default').click
        click_link 'version 1'
      end
      expect(page).to have_content '0 changed files'
    end
  end

  describe 'compare with newer version' do
    before do
      page.within '.mr-version-compare-dropdown' do
        find('.btn-default').click
        click_link 'version 2'
      end
    end

    it 'should set the compared versions to be the same' do
      page.within '.mr-version-compare-dropdown' do
        expect(find('.dropdown-toggle')).to have_content 'version 2'
      end

      page.within '.mr-version-dropdown' do
        find('.btn-default').click
        click_link 'version 1'
      end

      page.within '.mr-version-compare-dropdown' do
        expect(page).to have_content 'version 1'
      end

      expect(page).to have_content '0 changed files'
    end
  end
end
