require 'spec_helper'

describe Guard::TypeScript::Runner do
  let(:runner) { Guard::TypeScript::Runner }
  let(:watcher) { Guard::Watcher.new('^(.+)\.(?:ts)$') }
  let(:formatter) { Guard::TypeScript::Formatter }

  before do
    runner.stub(:compile).and_return ''
    formatter.stub(:notify)

    FileUtils.stub(:mkdir_p)
    FileUtils.stub(:remove_file)
    File.stub(:open)
  end

  describe '#run' do
    context 'without the :noop option' do
      it 'shows a start notification' do
        expect(formatter).to receive(:info).once.with('Compile a.ts, b.ts', { :reset => true })
        expect(formatter).to receive(:success).once.with('Successfully generated ')
        runner.run(['a.ts', 'b.ts'], [])
      end
    end

    context 'with the :noop option' do
      it 'shows a start notification' do
        expect(formatter).to receive(:info).once.with('Verify a.ts, b.ts', { :reset => true })
        expect(formatter).to receive(:success).once.with('Successfully verified ')
        runner.run(['a.ts', 'b.ts'], [], { :noop => true })
      end
    end

    context 'without a nested directory' do
      let(:watcher) { Guard::Watcher.new(%r{src/.+\.ts$}) }

      context 'without the :noop option' do
        it 'compiles the TypeScripts to the output and replace .ts with .js' do
          runner.run(['src/a.ts', 'src/b.ts'], [watcher], { :output => 'target' })
          expect(File).to exist("#{ @project_path }/target/a.js")
          expect(File).to exist("#{ @project_path }/target/b.js")
        end

        it 'compiles the TypeScripts to the output and replace .js.ts with .js' do
          runner.run(['src/a.js.ts', 'src/b.js.ts'], [watcher], { :output => 'target' })
          expect(File).to exist("#{ @project_path }/target/a.js")
          expect(File).to exist("#{ @project_path }/target/b.js")
        end
      end

      context 'without the :output option' do
        it 'compiles the TypeScripts to the same dir like the file and replace .ts with .js' do
          runner.run(['src/a.ts', 'src/b.ts'], [watcher])
          expect(File).to exist("#{ @project_path }/src/a.js")
          expect(File).to exist("#{ @project_path }/src/b.js")
        end

        it 'compiles the TypeScripts to the same dir like the file and replace .js.ts with .js' do
          runner.run(['src/a.js.ts', 'src/b.js.ts'], [watcher])
          expect(File).to exist("#{ @project_path }/src/a.js")
          expect(File).to exist("#{ @project_path }/src/b.js")
        end
      end

      context 'with the :noop option' do
        it 'does not write the output file' do
          runner.run(['src/a.js.ts', 'src/b.js.ts'], [watcher], { :output => 'target', :noop => true })
          expect(File).not_to exist("#{ @project_path }/src/a.js")
          expect(File).not_to exist("#{ @project_path }/src/b.js")
        end
      end

      context 'with the :source_map option' do
        it 'compiles the source map to the same dir like the file and replace .ts with .js.map' do
          runner.run(['src/a.ts', 'src/b.ts'], [watcher], :source_map => true)
          expect(File).to exist("#{ @project_path }/src/a.js.map")
          expect(File).to exist("#{ @project_path }/src/b.js.map")
        end

        it 'compiles the source map to the same dir like the file and replace .js.ts with .js.map' do
          runner.run(['src/a.js.ts', 'src/b.js.ts'], [watcher], :source_map => true)
          expect(File).to exist("#{ @project_path }/src/a.js.map")
          expect(File).to exist("#{ @project_path }/src/b.js.map")
        end
      end
    end

    context 'with the :shallow option set to false' do
      let(:watcher) { Guard::Watcher.new('^app/typescripts/(.+)\.(?:ts)$') }

      it 'compiles the TypeScripts to the output and creates nested directories' do
        runner.run(['app/typescripts/x/y/a.ts', 'app/typescripts/x/y/b.ts'],
                   [watcher], { :output => 'javascripts', :shallow => false })
        expect(File).to exist("#{ @project_path }/javascripts/x/y/a.js")
        expect(File).to exist("#{ @project_path }/javascripts/x/y/b.js")
      end

      context 'with the :source_map option' do
        it 'generates the source map to the output and creates nested directories' do
          runner.run(['app/typescripts/x/y/a.ts', 'app/typescripts/x/y/b.ts'],
                     [watcher], { :output => 'javascripts', :shallow => false, :source_map => true })
          expect(File).to exist("#{ @project_path }/javascripts/x/y/a.js.map")
          expect(File).to exist("#{ @project_path }/javascripts/x/y/b.js.map")
        end
      end
    end

    context 'with the :shallow option set to true' do
      let(:watcher) { Guard::Watcher.new('^app/typescripts/(.+)\.(?:ts)$') }

      it 'compiles the TypeScripts to the output without creating nested directories' do
        runner.run(['app/typescripts/x/y/a.ts', 'app/typescripts/x/y/b.ts'],
                   [watcher], { :output => 'javascripts', :shallow => true })
        expect(File).to exist("#{ @project_path }/javascripts/a.js")
        expect(File).to exist("#{ @project_path }/javascripts/b.js")
      end

      context 'with the :source_map option' do
        it 'generates the source map to the output without creating nested directories' do
          runner.run(['app/typescripts/x/y/a.ts', 'app/typescripts/x/y/b.ts'],
                     [watcher], { :output => 'javascripts', :shallow => true, :source_map => true })
          expect(File).to exist("#{ @project_path }/javascripts/a.js.map")
          expect(File).to exist("#{ @project_path }/javascripts/b.js.map")
        end
      end
    end

    context 'with the :source_map option' do
      before do
        runner.unstub(:compile)
        ::TypeScript.stub(:compile_file)
        File.stub(:read) { |file| file }
      end

      after do
        runner.stub(:compile).and_return ''
        ::TypeScript.unstub(:compile_file)
      end

      it 'compiles with source map file options set' do
        ::TypeScript.should_receive(:compile_file).with 'src/a.ts', hash_including({
          :sourceMap => true,
          :generatedFile => 'a.js',
          :sourceFiles => ['a.ts'],
          :sourceRoot => 'src',
        })
        runner.run(['src/a.ts'], [watcher], { :output => 'target', :source_map => true, :input => 'src' })
      end

      it 'accepts a different source_root' do
        ::TypeScript.should_receive(:compile_file).with 'src/a.ts', hash_including(:sourceRoot => 'foo')
        runner.run(['src/a.ts'], [watcher], { :output => 'target', :source_map => true, :source_root => 'foo' })
      end
    end

    context 'with compilation errors' do
      context 'without the :noop option' do
        it 'shows the error messages' do
          runner.should_receive(:compile).and_raise ::TypeScript::Error.new("Parse error on line 2: Unexpected 'UNARY'")
          expect(formatter).to receive(:error).once.with("a.ts: Parse error on line 2: Unexpected 'UNARY'")
          expect(formatter).to receive(:notify).with("a.ts: Parse error on line 2: Unexpected 'UNARY'",
                                                     :title => 'TypeScript results',
                                                     :image => :failed,
                                                     :priority => 2)
          runner.run(['a.ts'], [watcher], { :output => 'javascripts' })
        end
      end
      context 'with the :noop option' do
        it 'shows the error messages' do
          runner.should_receive(:compile).and_raise Guard::TypeScript::Error.new("Parse error on line 2: Unexpected 'UNARY'")
          expect(formatter).to receive(:error).once.with("a.ts: Parse error on line 2: Unexpected 'UNARY'")
          expect(formatter).to receive(:notify).with("a.ts: Parse error on line 2: Unexpected 'UNARY'",
                                                     :title => 'TypeScript results',
                                                     :image => :failed,
                                                     :priority => 2)
          runner.run(['a.ts'], [watcher], { :output => 'javascripts', :noop => true })
        end
      end

      context 'with the :error_to_js option' do
        it 'write the error message as javascript file' do
          runner.should_receive(:compile).and_raise Guard::TypeScript::Error.new("Parse error on line 2: Unexpected 'UNARY'")
          runner.should_receive(:write_javascript_file).once.with("throw \"a.ts: Parse error on line 2: Unexpected 'UNARY'\";", nil, 'a.ts', 'javascripts', kind_of(Hash))
          runner.run(['a.ts'], [watcher], { :output => 'javascripts', :error_to_js => true })
        end
      end
    end

    context 'without compilation errors' do
      context 'without the :noop option' do
        it 'shows a success messages' do
          expect(formatter).to receive(:success).once.with('Successfully generated javascripts/a.js')
          expect(formatter).to receive(:notify).with('Successfully generated javascripts/a.js',
                                                     :title => 'TypeScript results')
          runner.run(['a.ts'], [watcher], { :output => 'javascripts' })
        end
      end

      context 'with the :noop option' do
        it 'shows a success messages' do
          expect(formatter).to receive(:success).once.with('Successfully verified javascripts/a.js')
          expect(formatter).to receive(:notify).with('Successfully verified javascripts/a.js',
                                                     :title => 'TypeScript results')
          runner.run(['a.ts'], [watcher], { :output => 'javascripts',
                                            :noop => true })
        end
      end

      context 'with the :hide_success option set to true' do
        let(:watcher) { Guard::Watcher.new('^app/typescripts/.+\.(?:ts)$') }

        it 'does not show the success message' do
          expect(formatter).not_to receive(:success).with('Successfully generated javascripts/a.js')
          expect(formatter).not_to receive(:notify).with('Successfully generated javascripts/a.js',
                                                         :title => 'TypeScript results')
          runner.run(['app/typescripts/x/y/a.ts'], [watcher], { :output => 'javascripts',
                                                                :hide_success => true })
        end
      end
    end
=begin
    context 'with :hide_success over multiple runs' do
      it 'shows the failure message every time' do
        runner.should_receive(:compile).twice.and_raise Guard::TypeScript::Error.new("Parse error on line 2: Unexpected 'UNARY'")
        expect(formatter).to receive(:error).twice.with("a.ts: Parse error on line 2: Unexpected 'UNARY'")
        expect(formatter).to receive(:notify).twice.with("a.ts: Parse error on line 2: Unexpected 'UNARY'",
                                               :title => 'TypeScript results',
                                               :image => :failed,
                                               :priority => 2)

        2.times { runner.run(['a.ts'], [watcher], { :output => 'javascripts' }) }
      end

      it 'shows the success message only when previous attempt was failure' do
        runner.should_receive(:compile).and_raise Guard::TypeScript::Error.new("Parse error on line 2: Unexpected 'UNARY'")
        runner.run(['a.ts'], [watcher], { :output => 'javascripts',
                                              :hide_success => true })

        runner.stub(:compile).and_return ''
        expect(formatter).to receive(:success).with('Successfully generated javascripts/a.js')
        expect(formatter).to receive(:notify).with('Successfully generated javascripts/a.js',
                                                   :title => 'TypeScript results')
        runner.run(['a.ts'], [watcher], { :output => 'javascripts',
                                              :hide_success => true })
      end
    end
=end
  end

  describe '#remove' do
    let(:watcher) { Guard::Watcher.new(%r{src/.+\.(?:ts)$}) }

    before do
      expect(File).to receive(:exists?).with('target/a.js').and_return true
      expect(File).to receive(:exists?).with('target/b.js').and_return true
    end

    it 'removes the files' do
      expect(FileUtils).to receive(:remove_file).with('target/a.js')
      expect(FileUtils).to receive(:remove_file).with('target/b.js')
      runner.remove(['src/a.ts', 'src/b.ts'], [watcher], { :output => 'target' })
    end

    it 'shows a notification' do
      expect(formatter).to receive(:success).once.with('Removed target/a.js, target/b.js')
      expect(formatter).to receive(:notify).with('Removed target/a.js, target/b.js',
                                                 :title => 'TypeScript results')
      runner.remove(['src/a.ts', 'src/b.ts'], [watcher], { :output => 'target' })
    end
  end
end