require 'spec_helper'

describe Gitlab::SlashCommands::Dsl do
  before :all do
    DummyClass = Struct.new(:project) do
      include Gitlab::SlashCommands::Dsl

      desc 'A command with no args'
      command :no_args, :none do
        "Hello World!"
      end

      params 'The first argument'
      humanized 'Static explanation'
      command :explanation_with_aliases, :once, :first do |arg|
        arg
      end

      desc do
        "A dynamic description for #{noteable.upcase}"
      end
      params 'The first argument', 'The second argument'
      command :dynamic_description do |args|
        args.split
      end

      command :cc

      humanized do |arg|
        "Action does something with #{arg}"
      end
      condition do
        project == 'foo'
      end
      command :cond_action do |arg|
        arg
      end
    end
  end

  describe '.command_definitions' do
    it 'returns an array with commands definitions' do
      no_args_def, explanation_with_aliases_def, dynamic_description_def, cc_def, cond_action_def =
        DummyClass.command_definitions

      expect(no_args_def.name).to eq(:no_args)
      expect(no_args_def.aliases).to eq([:none])
      expect(no_args_def.description).to eq('A command with no args')
      expect(no_args_def.humanized).to eq('')
      expect(no_args_def.params).to eq([])
      expect(no_args_def.condition_block).to be_nil
      expect(no_args_def.action_block).to be_a_kind_of(Proc)

      expect(explanation_with_aliases_def.name).to eq(:explanation_with_aliases)
      expect(explanation_with_aliases_def.aliases).to eq([:once, :first])
      expect(explanation_with_aliases_def.description).to eq('')
      expect(explanation_with_aliases_def.humanized).to eq('Static explanation')
      expect(explanation_with_aliases_def.params).to eq(['The first argument'])
      expect(explanation_with_aliases_def.condition_block).to be_nil
      expect(explanation_with_aliases_def.action_block).to be_a_kind_of(Proc)

      expect(dynamic_description_def.name).to eq(:dynamic_description)
      expect(dynamic_description_def.aliases).to eq([])
      expect(dynamic_description_def.to_h(noteable: 'issue')[:description]).to eq('A dynamic description for ISSUE')
      expect(dynamic_description_def.humanized).to eq('')
      expect(dynamic_description_def.params).to eq(['The first argument', 'The second argument'])
      expect(dynamic_description_def.condition_block).to be_nil
      expect(dynamic_description_def.action_block).to be_a_kind_of(Proc)

      expect(cc_def.name).to eq(:cc)
      expect(cc_def.aliases).to eq([])
      expect(cc_def.description).to eq('')
      expect(cc_def.humanized).to eq('')
      expect(cc_def.params).to eq([])
      expect(cc_def.condition_block).to be_nil
      expect(cc_def.action_block).to be_nil

      expect(cond_action_def.name).to eq(:cond_action)
      expect(cond_action_def.aliases).to eq([])
      expect(cond_action_def.description).to eq('')
      expect(cond_action_def.humanized).to be_a_kind_of(Proc)
      expect(cond_action_def.params).to eq([])
      expect(cond_action_def.condition_block).to be_a_kind_of(Proc)
      expect(cond_action_def.action_block).to be_a_kind_of(Proc)
    end
  end
end
