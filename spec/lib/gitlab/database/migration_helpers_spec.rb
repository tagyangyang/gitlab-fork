require 'spec_helper'

describe Gitlab::Database::MigrationHelpers, lib: true do
  let(:model) do
    ActiveRecord::Migration.new.extend(
      Gitlab::Database::MigrationHelpers
    )
  end

  before { allow(model).to receive(:puts) }

  describe '#add_concurrent_index' do
    context 'outside a transaction' do
      before do
        allow(model).to receive(:transaction_open?).and_return(false)
      end

      context 'using PostgreSQL' do
        before do
          allow(Gitlab::Database).to receive(:postgresql?).and_return(true)
          allow(model).to receive(:disable_statement_timeout)
        end

        it 'creates the index concurrently' do
          expect(model).to receive(:add_index).
            with(:users, :foo, algorithm: :concurrently)

          model.add_concurrent_index(:users, :foo)
        end

        it 'creates unique index concurrently' do
          expect(model).to receive(:add_index).
            with(:users, :foo, { algorithm: :concurrently, unique: true })

          model.add_concurrent_index(:users, :foo, unique: true)
        end
      end

      context 'using MySQL' do
        it 'creates a regular index' do
          expect(Gitlab::Database).to receive(:postgresql?).and_return(false)

          expect(model).to receive(:add_index).
            with(:users, :foo, {})

          model.add_concurrent_index(:users, :foo)
        end
      end
    end

    context 'inside a transaction' do
      it 'raises RuntimeError' do
        expect(model).to receive(:transaction_open?).and_return(true)

        expect { model.add_concurrent_index(:users, :foo) }.
          to raise_error(RuntimeError)
      end
    end
  end

  describe '#remove_concurrent_index' do
    context 'outside a transaction' do
      before do
        allow(model).to receive(:transaction_open?).and_return(false)
      end

      context 'using PostgreSQL' do
        before do
          allow(Gitlab::Database).to receive(:postgresql?).and_return(true)
          allow(model).to receive(:disable_statement_timeout)
        end

        it 'removes the index concurrently' do
          expect(model).to receive(:remove_index).
            with(:users, { algorithm: :concurrently, column: :foo })

          model.remove_concurrent_index(:users, :foo)
        end
      end

      context 'using MySQL' do
        it 'removes an index' do
          expect(Gitlab::Database).to receive(:postgresql?).and_return(false)

          expect(model).to receive(:remove_index).
            with(:users, { column: :foo })

          model.remove_concurrent_index(:users, :foo)
        end
      end
    end

    context 'inside a transaction' do
      it 'raises RuntimeError' do
        expect(model).to receive(:transaction_open?).and_return(true)

        expect { model.remove_concurrent_index(:users, :foo) }.
          to raise_error(RuntimeError)
      end
    end
  end

  describe '#add_concurrent_foreign_key' do
    context 'inside a transaction' do
      it 'raises an error' do
        expect(model).to receive(:transaction_open?).and_return(true)

        expect do
          model.add_concurrent_foreign_key(:projects, :users, column: :user_id)
        end.to raise_error(RuntimeError)
      end
    end

    context 'outside a transaction' do
      before do
        allow(model).to receive(:transaction_open?).and_return(false)
      end

      context 'using MySQL' do
        it 'creates a regular foreign key' do
          allow(Gitlab::Database).to receive(:mysql?).and_return(true)

          expect(model).to receive(:add_foreign_key).
            with(:projects, :users, column: :user_id, on_delete: :cascade)

          model.add_concurrent_foreign_key(:projects, :users, column: :user_id)
        end
      end

      context 'using PostgreSQL' do
        before do
          allow(Gitlab::Database).to receive(:mysql?).and_return(false)
        end

        it 'creates a concurrent foreign key' do
          expect(model).to receive(:disable_statement_timeout)
          expect(model).to receive(:execute).ordered.with(/NOT VALID/)
          expect(model).to receive(:execute).ordered.with(/VALIDATE CONSTRAINT/)

          model.add_concurrent_foreign_key(:projects, :users, column: :user_id)
        end
      end
    end
  end

  describe '#concurrent_foreign_key_name' do
    it 'returns the name for a foreign key' do
      name = model.concurrent_foreign_key_name(:this_is_a_very_long_table_name,
                                               :with_a_very_long_column_name)

      expect(name).to be_an_instance_of(String)
      expect(name.length).to eq(13)
    end
  end

  describe '#disable_statement_timeout' do
    context 'using PostgreSQL' do
      it 'disables statement timeouts' do
        expect(Gitlab::Database).to receive(:postgresql?).and_return(true)

        expect(model).to receive(:execute).with('SET statement_timeout TO 0')

        model.disable_statement_timeout
      end
    end

    context 'using MySQL' do
      it 'does nothing' do
        expect(Gitlab::Database).to receive(:postgresql?).and_return(false)

        expect(model).not_to receive(:execute)

        model.disable_statement_timeout
      end
    end
  end

  describe '#update_column_in_batches' do
    before do
      create_list(:empty_project, 5)
    end

    it 'updates all the rows in a table' do
      model.update_column_in_batches(:projects, :import_error, 'foo')

      expect(Project.where(import_error: 'foo').count).to eq(5)
    end

    it 'updates boolean values correctly' do
      model.update_column_in_batches(:projects, :archived, true)

      expect(Project.where(archived: true).count).to eq(5)
    end

    context 'when a block is supplied' do
      it 'yields an Arel table and query object to the supplied block' do
        first_id = Project.first.id

        model.update_column_in_batches(:projects, :archived, true) do |t, query|
          query.where(t[:id].eq(first_id))
        end

        expect(Project.where(archived: true).count).to eq(1)
      end
    end
  end

  describe '#add_column_with_default' do
    context 'outside of a transaction' do
      context 'when a column limit is not set' do
        before do
          expect(model).to receive(:transaction_open?).and_return(false)

          expect(model).to receive(:transaction).and_yield

          expect(model).to receive(:add_column).
            with(:projects, :foo, :integer, default: nil)

          expect(model).to receive(:change_column_default).
            with(:projects, :foo, 10)
        end

        it 'adds the column while allowing NULL values' do
          expect(model).to receive(:update_column_in_batches).
            with(:projects, :foo, 10)

          expect(model).not_to receive(:change_column_null)

          model.add_column_with_default(:projects, :foo, :integer,
                                        default: 10,
                                        allow_null: true)
        end

        it 'adds the column while not allowing NULL values' do
          expect(model).to receive(:update_column_in_batches).
            with(:projects, :foo, 10)

          expect(model).to receive(:change_column_null).
            with(:projects, :foo, false)

          model.add_column_with_default(:projects, :foo, :integer, default: 10)
        end

        it 'removes the added column whenever updating the rows fails' do
          expect(model).to receive(:update_column_in_batches).
            with(:projects, :foo, 10).
            and_raise(RuntimeError)

          expect(model).to receive(:remove_column).
            with(:projects, :foo)

          expect do
            model.add_column_with_default(:projects, :foo, :integer, default: 10)
          end.to raise_error(RuntimeError)
        end

        it 'removes the added column whenever changing a column NULL constraint fails' do
          expect(model).to receive(:change_column_null).
            with(:projects, :foo, false).
            and_raise(RuntimeError)

          expect(model).to receive(:remove_column).
            with(:projects, :foo)

          expect do
            model.add_column_with_default(:projects, :foo, :integer, default: 10)
          end.to raise_error(RuntimeError)
        end
      end

      context 'when a column limit is set' do
        it 'adds the column with a limit' do
          allow(model).to receive(:transaction_open?).and_return(false)
          allow(model).to receive(:transaction).and_yield
          allow(model).to receive(:update_column_in_batches).with(:projects, :foo, 10)
          allow(model).to receive(:change_column_null).with(:projects, :foo, false)
          allow(model).to receive(:change_column_default).with(:projects, :foo, 10)

          expect(model).to receive(:add_column).
            with(:projects, :foo, :integer, default: nil, limit: 8)

          model.add_column_with_default(:projects, :foo, :integer, default: 10, limit: 8)
        end
      end
    end

    context 'inside a transaction' do
      it 'raises RuntimeError' do
        expect(model).to receive(:transaction_open?).and_return(true)

        expect do
          model.add_column_with_default(:projects, :foo, :integer, default: 10)
        end.to raise_error(RuntimeError)
      end
    end
  end

  describe '#rename_column_concurrently' do
    context 'in a transaction' do
      it 'raises RuntimeError' do
        allow(model).to receive(:transaction_open?).and_return(true)

        expect { model.rename_column_concurrently(:users, :old, :new) }.
          to raise_error(RuntimeError)
      end
    end

    context 'outside a transaction' do
      let(:old_column) do
        double(:column,
               type: :integer,
               limit: 8,
               default: 0,
               null: false,
               precision: 5,
               scale: 1)
      end

      let(:trigger_name) { model.rename_trigger_name(:users, :old, :new) }

      before do
        allow(model).to receive(:transaction_open?).and_return(false)
        allow(model).to receive(:column_for).and_return(old_column)

        # Since MySQL and PostgreSQL use different quoting styles we'll just
        # stub the methods used for this to make testing easier.
        allow(model).to receive(:quote_column_name) { |name| name.to_s }
        allow(model).to receive(:quote_table_name) { |name| name.to_s }
      end

      context 'using MySQL' do
        it 'renames a column concurrently' do
          allow(Gitlab::Database).to receive(:postgresql?).and_return(false)

          expect(model).to receive(:install_rename_triggers_for_mysql).
            with(trigger_name, 'users', 'old', 'new')

          expect(model).to receive(:add_column).
            with(:users, :new, :integer,
                 limit: old_column.limit,
                 default: old_column.default,
                 null: old_column.null,
                 precision: old_column.precision,
                 scale: old_column.scale)

          expect(model).to receive(:update_column_in_batches)

          expect(model).to receive(:copy_indexes).with(:users, :old, :new)
          expect(model).to receive(:copy_foreign_keys).with(:users, :old, :new)

          model.rename_column_concurrently(:users, :old, :new)
        end
      end

      context 'using PostgreSQL' do
        it 'renames a column concurrently' do
          allow(Gitlab::Database).to receive(:postgresql?).and_return(true)

          expect(model).to receive(:install_rename_triggers_for_postgresql).
            with(trigger_name, 'users', 'old', 'new')

          expect(model).to receive(:add_column).
            with(:users, :new, :integer,
                 limit: old_column.limit,
                 default: old_column.default,
                 null: old_column.null,
                 precision: old_column.precision,
                 scale: old_column.scale)

          expect(model).to receive(:update_column_in_batches)

          expect(model).to receive(:copy_indexes).with(:users, :old, :new)
          expect(model).to receive(:copy_foreign_keys).with(:users, :old, :new)

          model.rename_column_concurrently(:users, :old, :new)
        end
      end
    end
  end

  describe '#cleanup_concurrent_column_rename' do
    it 'cleans up the renaming procedure for PostgreSQL' do
      allow(Gitlab::Database).to receive(:postgresql?).and_return(true)

      expect(model).to receive(:remove_rename_triggers_for_postgresql).
        with(:users, /trigger_.{12}/)

      expect(model).to receive(:remove_column).with(:users, :old)

      model.cleanup_concurrent_column_rename(:users, :old, :new)
    end

    it 'cleans up the renaming procedure for MySQL' do
      allow(Gitlab::Database).to receive(:postgresql?).and_return(false)

      expect(model).to receive(:remove_rename_triggers_for_mysql).
        with(/trigger_.{12}/)

      expect(model).to receive(:remove_column).with(:users, :old)

      model.cleanup_concurrent_column_rename(:users, :old, :new)
    end
  end

  describe '#change_column_type_concurrently' do
    it 'changes the column type' do
      expect(model).to receive(:rename_column_concurrently).
        with('users', 'username', 'username_for_type_change', type: :text)

      model.change_column_type_concurrently('users', 'username', :text)
    end
  end

  describe '#cleanup_concurrent_column_type_change' do
    it 'cleans up the type changing procedure' do
      expect(model).to receive(:cleanup_concurrent_column_rename).
        with('users', 'username', 'username_for_type_change')

      expect(model).to receive(:rename_column).
        with('users', 'username_for_type_change', 'username')

      model.cleanup_concurrent_column_type_change('users', 'username')
    end
  end

  describe '#install_rename_triggers_for_postgresql' do
    it 'installs the triggers for PostgreSQL' do
      expect(model).to receive(:execute).
        with(/CREATE OR REPLACE FUNCTION foo()/m)

      expect(model).to receive(:execute).
        with(/CREATE TRIGGER foo/m)

      model.install_rename_triggers_for_postgresql('foo', :users, :old, :new)
    end
  end

  describe '#install_rename_triggers_for_mysql' do
    it 'installs the triggers for MySQL' do
      expect(model).to receive(:execute).
        with(/CREATE TRIGGER foo_insert.+ON users/m)

      expect(model).to receive(:execute).
        with(/CREATE TRIGGER foo_update.+ON users/m)

      model.install_rename_triggers_for_mysql('foo', :users, :old, :new)
    end
  end

  describe '#remove_rename_triggers_for_postgresql' do
    it 'removes the function and trigger' do
      expect(model).to receive(:execute).with('DROP TRIGGER foo ON bar')
      expect(model).to receive(:execute).with('DROP FUNCTION foo()')

      model.remove_rename_triggers_for_postgresql('bar', 'foo')
    end
  end

  describe '#remove_rename_triggers_for_mysql' do
    it 'removes the triggers' do
      expect(model).to receive(:execute).with('DROP TRIGGER foo_insert')
      expect(model).to receive(:execute).with('DROP TRIGGER foo_update')

      model.remove_rename_triggers_for_mysql('foo')
    end
  end

  describe '#rename_trigger_name' do
    it 'returns a String' do
      expect(model.rename_trigger_name(:users, :foo, :bar)).
        to match(/trigger_.{12}/)
    end
  end

  describe '#indexes_for' do
    it 'returns the indexes for a column' do
      idx1 = double(:idx, columns: %w(project_id))
      idx2 = double(:idx, columns: %w(user_id))

      allow(model).to receive(:indexes).with('table').and_return([idx1, idx2])

      expect(model.indexes_for('table', :user_id)).to eq([idx2])
    end
  end

  describe '#foreign_keys_for' do
    it 'returns the foreign keys for a column' do
      fk1 = double(:fk, column: 'project_id')
      fk2 = double(:fk, column: 'user_id')

      allow(model).to receive(:foreign_keys).with('table').and_return([fk1, fk2])

      expect(model.foreign_keys_for('table', :user_id)).to eq([fk2])
    end
  end

  describe '#copy_indexes' do
    context 'using a regular index using a single column' do
      it 'copies the index' do
        index = double(:index,
                       columns: %w(project_id),
                       name: 'index_on_issues_project_id',
                       using: nil,
                       where: nil,
                       opclasses: {},
                       unique: false,
                       lengths: [],
                       orders: [])

        allow(model).to receive(:indexes_for).with(:issues, 'project_id').
          and_return([index])

        expect(model).to receive(:add_concurrent_index).
          with(:issues,
               %w(gl_project_id),
               unique: false,
               name: 'index_on_issues_gl_project_id',
               length: [],
               order: [])

        model.copy_indexes(:issues, :project_id, :gl_project_id)
      end
    end

    context 'using a regular index with multiple columns' do
      it 'copies the index' do
        index = double(:index,
                       columns: %w(project_id foobar),
                       name: 'index_on_issues_project_id_foobar',
                       using: nil,
                       where: nil,
                       opclasses: {},
                       unique: false,
                       lengths: [],
                       orders: [])

        allow(model).to receive(:indexes_for).with(:issues, 'project_id').
          and_return([index])

        expect(model).to receive(:add_concurrent_index).
          with(:issues,
               %w(gl_project_id foobar),
               unique: false,
               name: 'index_on_issues_gl_project_id_foobar',
               length: [],
               order: [])

        model.copy_indexes(:issues, :project_id, :gl_project_id)
      end
    end

    context 'using an index with a WHERE clause' do
      it 'copies the index' do
        index = double(:index,
                       columns: %w(project_id),
                       name: 'index_on_issues_project_id',
                       using: nil,
                       where: 'foo',
                       opclasses: {},
                       unique: false,
                       lengths: [],
                       orders: [])

        allow(model).to receive(:indexes_for).with(:issues, 'project_id').
          and_return([index])

        expect(model).to receive(:add_concurrent_index).
          with(:issues,
               %w(gl_project_id),
               unique: false,
               name: 'index_on_issues_gl_project_id',
               length: [],
               order: [],
               where: 'foo')

        model.copy_indexes(:issues, :project_id, :gl_project_id)
      end
    end

    context 'using an index with a USING clause' do
      it 'copies the index' do
        index = double(:index,
                       columns: %w(project_id),
                       name: 'index_on_issues_project_id',
                       where: nil,
                       using: 'foo',
                       opclasses: {},
                       unique: false,
                       lengths: [],
                       orders: [])

        allow(model).to receive(:indexes_for).with(:issues, 'project_id').
          and_return([index])

        expect(model).to receive(:add_concurrent_index).
          with(:issues,
               %w(gl_project_id),
               unique: false,
               name: 'index_on_issues_gl_project_id',
               length: [],
               order: [],
               using: 'foo')

        model.copy_indexes(:issues, :project_id, :gl_project_id)
      end
    end

    context 'using an index with custom operator classes' do
      it 'copies the index' do
        index = double(:index,
                       columns: %w(project_id),
                       name: 'index_on_issues_project_id',
                       using: nil,
                       where: nil,
                       opclasses: { 'project_id' => 'bar' },
                       unique: false,
                       lengths: [],
                       orders: [])

        allow(model).to receive(:indexes_for).with(:issues, 'project_id').
          and_return([index])

        expect(model).to receive(:add_concurrent_index).
          with(:issues,
               %w(gl_project_id),
               unique: false,
               name: 'index_on_issues_gl_project_id',
               length: [],
               order: [],
               opclasses: { 'gl_project_id' => 'bar' })

        model.copy_indexes(:issues, :project_id, :gl_project_id)
      end
    end

    describe 'using an index of which the name does not contain the source column' do
      it 'raises RuntimeError' do
        index = double(:index,
                       columns: %w(project_id),
                       name: 'index_foobar_index',
                       using: nil,
                       where: nil,
                       opclasses: {},
                       unique: false,
                       lengths: [],
                       orders: [])

        allow(model).to receive(:indexes_for).with(:issues, 'project_id').
          and_return([index])

        expect { model.copy_indexes(:issues, :project_id, :gl_project_id) }.
          to raise_error(RuntimeError)
      end
    end
  end

  describe '#copy_foreign_keys' do
    it 'copies foreign keys from one column to another' do
      fk = double(:fk,
                  from_table: 'issues',
                  to_table: 'projects',
                  on_delete: :cascade)

      allow(model).to receive(:foreign_keys_for).with(:issues, :project_id).
        and_return([fk])

      expect(model).to receive(:add_concurrent_foreign_key).
        with('issues', 'projects', column: :gl_project_id, on_delete: :cascade)

      model.copy_foreign_keys(:issues, :project_id, :gl_project_id)
    end
  end

  describe '#column_for' do
    it 'returns a column object for an existing column' do
      column = model.column_for(:users, :id)

      expect(column.name).to eq('id')
    end

    it 'returns nil when a column does not exist' do
      expect(model.column_for(:users, :kittens)).to be_nil
    end
  end
end
