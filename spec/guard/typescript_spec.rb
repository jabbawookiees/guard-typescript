require 'spec_helper'

describe Guard::TypeScript do

  let(:guard) { Guard::TypeScript.new }

  let(:runner) { Guard::TypeScript::Runner }
  let(:inspector) { Guard::TypeScript::Inspector }

  let(:defaults) { Guard::TypeScript::DEFAULT_OPTIONS }

  before do
    inspector.stub(:clean)
    runner.stub(:run)
    runner.stub(:remove)
  end

  describe '#initialize' do
    context 'when no options are provided' do
      it 'sets a default :shallow option' do
        guard.options[:shallow].should be_falsey
      end

      it 'sets a default :hide_success option' do
        guard.options[:hide_success].should be_falsey
      end

      it 'sets a default :noop option' do
        guard.options[:noop].should be_falsey
      end

      it 'sets a default :all_on_start option' do
        guard.options[:all_on_start].should be_falsey
      end

      it 'sets the provided :source_maps option' do
        guard.options[:source_map].should be_falsey
      end

    end

    context 'with options besides the defaults' do
      let(:guard) { Guard::TypeScript.new(nil, { :output       => 'output_folder',
                                                 :shallow      => true,
                                                 :hide_success => true,
                                                 :all_on_start => true,
                                                 :noop         => true,
                                                 :source_map  => true
      }) }

      it 'sets the provided :shallow option' do
        guard.options[:shallow].should be_truthy
      end

      it 'sets the provided :hide_success option' do
        guard.options[:hide_success].should be_truthy
      end

      it 'sets the provided :noop option' do
        guard.options[:noop].should be_truthy
      end

      it 'sets the provided :all_on_start option' do
        guard.options[:all_on_start].should be_truthy
      end

      it 'sets the provided :source_maps option' do
        guard.options[:source_map].should be_truthy
      end
    end

    context 'with a input option' do
      let(:guard) { Guard::TypeScript.new(nil, { :input => 'app/typescripts' }) }

      it 'creates a watcher' do
        guard.watchers.length.should be >= 1
      end

      it 'watches all *.ts files' do
        guard.watchers.first.pattern.should eql %r{^app/typescripts/(.+\.(?:ts))$}
      end

      context 'without an output option' do
        it 'sets the output directory to the input directory' do
          guard.options[:output].should eql 'app/typescripts'
        end
      end

      context 'with an output option' do
        let(:guard) { Guard::TypeScript.new(nil, { :input  => 'app/typescripts',
                                                     :output => 'public/javascripts' }) }

        it 'keeps the output directory' do
          guard.options[:output].should eql 'public/javascripts'
        end
      end
    end
  end

  describe '#start' do
    it 'calls #run_all' do
      guard.should_not_receive(:run_all)
      guard.start
    end

    context 'with the :all_on_start option' do
      let(:guard) { Guard::TypeScript.new(nil, :all_on_start => true) }

      it 'calls #run_all' do
        guard.should_receive(:run_all)
        guard.start
      end
    end
  end

  describe '#run_all' do
    let(:guard) { Guard::TypeScript.new([Guard::Watcher.new('^x/.+\.ts$')]) }

    before do
      Dir.stub(:glob).and_return ['x/a.ts', 'x/b.ts', 'y/c.ts']
    end

    it 'runs the run_on_modifications with all watched TypeScript' do
      guard.should_receive(:run_on_modifications).with(['x/a.ts', 'x/b.ts'])
      guard.run_all
    end
  end

  describe '#run_on_modifications' do
    it 'throws :task_has_failed when an error occurs' do
      inspector.should_receive(:clean).with(['a.ts', 'b.ts']).and_return ['a.ts']
      runner.should_receive(:run).with(['a.ts'], [], defaults).and_return [[], false]
      expect { guard.run_on_modifications(['a.ts', 'b.ts']) }.to throw_symbol :task_has_failed
    end

    it 'starts the Runner with the cleaned files' do
      inspector.should_receive(:clean).with(['a.ts', 'b.ts']).and_return ['a.ts']
      runner.should_receive(:run).with(['a.ts'], [], defaults).and_return [['a.js'], true]
      guard.run_on_modifications(['a.ts', 'b.ts'])
    end
  end

  describe '#run_on_removals' do
    it 'cleans the paths accepting missing files' do
      inspector.should_receive(:clean).with(['a.ts', 'b.ts'], { :missing_ok => true })
      guard.run_on_removals(['a.ts', 'b.ts'])
    end

    it 'removes the files' do
      inspector.should_receive(:clean).and_return ['a.ts', 'b.ts']
      runner.should_receive(:remove).with(['a.ts', 'b.ts'], guard.watchers, guard.options)
      guard.run_on_removals(['a.ts', 'b.ts'])
    end
  end
end