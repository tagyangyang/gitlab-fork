require 'spec_helper'

feature 'Projects > Wiki > User creates wiki page', feature: true do
  let(:user) { create(:user) }

  background do
    project.team << [user, :master]
    login_as(user)

    visit namespace_project_path(project.namespace, project)
    click_link 'Wiki'
  end

  context 'in the user namespace' do
    let(:project) { create(:project, namespace: user.namespace) }

    context 'when wiki is empty' do
      scenario 'commit message field has value "Create home"' do
        expect(page).to have_field('wiki[message]', with: 'Create home')
      end

      scenario 'directly from the wiki home page' do
        fill_in :wiki_content, with: 'My awesome wiki!'
        page.within '.wiki-form' do
          click_button 'Create page'
        end
        expect(page).to have_content('Home')
        expect(page).to have_content("Last edited by #{user.name}")
        expect(page).to have_content('My awesome wiki!')
      end
    end

    context 'when wiki is not empty' do
      before do
        WikiPages::CreateService.new(project, user, title: 'home', content: 'Home page').execute
      end

      context 'via the "new wiki page" page' do
        scenario 'when the wiki page has a single word name', js: true do
          click_link 'New page'

          page.within '#modal-new-wiki' do
            fill_in :new_wiki_path, with: 'foo'
            click_button 'Create page'
          end

          # Commit message field should have correct value.
          expect(page).to have_field('wiki[message]', with: 'Create foo')

          page.within '.wiki-form' do
            fill_in :wiki_content, with: 'My awesome wiki!'
            click_button 'Create page'
          end

          expect(page).to have_content('Foo')
          expect(page).to have_content("Last edited by #{user.name}")
          expect(page).to have_content('My awesome wiki!')
        end

        scenario 'when the wiki page has spaces in the name', js: true do
          click_link 'New page'

          page.within '#modal-new-wiki' do
            fill_in :new_wiki_path, with: 'Spaces in the name'
            click_button 'Create page'
          end

          # Commit message field should have correct value.
          expect(page).to have_field('wiki[message]', with: 'Create spaces in the name')

          page.within '.wiki-form' do
            fill_in :wiki_content, with: 'My awesome wiki!'
            click_button 'Create page'
          end

          expect(page).to have_content('Spaces in the name')
          expect(page).to have_content("Last edited by #{user.name}")
          expect(page).to have_content('My awesome wiki!')
        end

        scenario 'when the wiki page has hyphens in the name', js: true do
          click_link 'New page'

          page.within '#modal-new-wiki' do
            fill_in :new_wiki_path, with: 'hyphens-in-the-name'
            click_button 'Create page'
          end

          # Commit message field should have correct value.
          expect(page).to have_field('wiki[message]', with: 'Create hyphens in the name')

          page.within '.wiki-form' do
            fill_in :wiki_content, with: 'My awesome wiki!'
            click_button 'Create page'
          end

          expect(page).to have_content('Hyphens in the name')
          expect(page).to have_content("Last edited by #{user.name}")
          expect(page).to have_content('My awesome wiki!')
        end
      end
    end
  end

  context 'in a group namespace' do
    let(:project) { create(:project, namespace: create(:group, :public)) }

    context 'when wiki is empty' do
      scenario 'commit message field has value "Create home"' do
        expect(page).to have_field('wiki[message]', with: 'Create home')
      end

      scenario 'directly from the wiki home page' do
        fill_in :wiki_content, with: 'My awesome wiki!'
        page.within '.wiki-form' do
          click_button 'Create page'
        end

        expect(page).to have_content('Home')
        expect(page).to have_content("Last edited by #{user.name}")
        expect(page).to have_content('My awesome wiki!')
      end
    end

    context 'when wiki is not empty' do
      before do
        WikiPages::CreateService.new(project, user, title: 'home', content: 'Home page').execute
      end

      scenario 'via the "new wiki page" page', js: true do
        click_link 'New page'

        page.within '#modal-new-wiki' do
          fill_in :new_wiki_path, with: 'foo'
          click_button 'Create page'
        end

        # Commit message field should have correct value.
        expect(page).to have_field('wiki[message]', with: 'Create foo')

        page.within '.wiki-form' do
          fill_in :wiki_content, with: 'My awesome wiki!'
          click_button 'Create page'
        end

        expect(page).to have_content('Foo')
        expect(page).to have_content("Last edited by #{user.name}")
        expect(page).to have_content('My awesome wiki!')
      end
    end
  end
end
