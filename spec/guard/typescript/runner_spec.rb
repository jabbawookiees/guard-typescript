require 'spec_helper'

describe Guard::TypeScript::Runner do
  let(:runner) { Guard::TypeScript::Runner }
  let(:watcher) { Guard::Watcher.new('^(.+)\.(?:ts)$') }
  let(:formatter) { Guard::TypeScript::Formatter }
  let(:bad_error_message) { "src/bad.ts: src/bad.ts(1,6): error TS1005: ';' expected.\nsrc/bad.ts(1,9): error TS1005: ';' expected.\nsrc/bad.ts(1,11): error TS1005: ';' expected.\nsrc/bad.ts(1,18): error TS1005: ';' expected.\n" }

  before do
    formatter.stub(:notify)
  end

  before(:each) do
    FileUtils.rm_rf("#{ @project_path }/src")
    FileUtils.rm_rf("#{ @project_path }/target")
    FileUtils.cp_r("#{ @project_path }/spec/data", "#{ @project_path }/src")
  end

  after(:each) do
    FileUtils.rm_rf("#{ @project_path }/src")
    FileUtils.rm_rf("#{ @project_path }/target")
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
      let(:watcher) { Guard::Watcher.new(%r{src/(.+\.(?:ts))$}) }
      context 'without the :noop option' do
        it 'compiles the TypeScripts to the output and replace .ts with .js' do
          runner.run(['src/a.ts', 'src/b.ts'], [watcher], { :output => 'target' })
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
      end

      context 'with the :noop option' do
        it 'does not write the output file' do
          runner.run(['src/a.ts', 'src/b.ts'], [watcher], { :output => 'target', :noop => true })
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
      end
    end

    context 'with the :shallow option set to false' do
      let(:watcher) { Guard::Watcher.new(%r{src/(.+\.(?:ts))$}) }

      it 'compiles the TypeScripts to the output and creates nested directories' do
        runner.run(['src/x/y/z/a.ts', 'src/x/y/z/b.ts'],
                   [watcher], { :output => 'target', :shallow => false })
        expect(File).to exist("#{ @project_path }/target/x/y/z/a.js")
        expect(File).to exist("#{ @project_path }/target/x/y/z/b.js")
      end

      context 'with the :source_map option' do
        it 'generates the source map to the output and creates nested directories' do
          runner.run(['src/x/y/z/a.ts', 'src/x/y/z/b.ts'],
                     [watcher], { :output => 'target', :shallow => false, :source_map => true })
          expect(File).to exist("#{ @project_path }/target/x/y/z/a.js.map")
          expect(File).to exist("#{ @project_path }/target/x/y/z/b.js.map")
        end
      end
    end

    context 'with the :shallow option set to true' do
      let(:watcher) { Guard::Watcher.new(%r{src/(.+\.(?:ts))$}) }

      it 'compiles the TypeScripts to the output without creating nested directories' do
        runner.run(['src/x/y/z/a.ts', 'src/x/y/z/b.ts'],
                   [watcher], { :output => 'target', :shallow => true })
        expect(File).to exist("#{ @project_path }/target/a.js")
        expect(File).to exist("#{ @project_path }/target/b.js")
      end

      context 'with the :source_map option' do
        it 'generates the source map to the output without creating nested directories' do
          runner.run(['src/x/y/z/a.ts', 'src/x/y/z/b.ts'],
                     [watcher], { :output => 'target', :shallow => true, :source_map => true })
          expect(File).to exist("#{ @project_path }/target/a.js.map")
          expect(File).to exist("#{ @project_path }/target/b.js.map")
        end
      end
    end

    context 'with the :source_map option' do
      let(:watcher) { Guard::Watcher.new(%r{src/(.+\.(?:ts))$}) }

      it 'compiles with source map file options set' do
        expect(::TypeScript).to receive(:compile_file).with 'src/a.ts', hash_including({
          :source_map => true,
        })
        runner.run(['src/a.ts'], [watcher], { :output => 'target', :source_map => true, :input => 'src' })
      end

      it 'accepts a different source_root' do
        expect(::TypeScript).to receive(:compile_file).with 'src/a.ts', hash_including(:source_root => 'foo')
        runner.run(['src/a.ts'], [watcher], { :output => 'target', :source_map => true, :source_root => 'foo' })
      end
    end

    context 'with compilation errors' do
      let(:watcher) { Guard::Watcher.new(%r{src/(.+\.(?:ts))$}) }
      context 'without the :noop option' do
        it 'shows the error messages' do
          expect(formatter).to receive(:error).once.with(bad_error_message)
          expect(formatter).to receive(:notify).with(bad_error_message,
                                                     :title => 'TypeScript results',
                                                     :image => :failed,
                                                     :priority => 2)
          runner.run(['src/bad.ts'], [watcher], { :output => 'target' })
        end
      end
      context 'with the :noop option' do
        it 'shows the error messages' do
          expect(formatter).to receive(:error).once.with(bad_error_message)
          expect(formatter).to receive(:notify).with(bad_error_message,
                                                     :title => 'TypeScript results',
                                                     :image => :failed,
                                                     :priority => 2)
          runner.run(['src/bad.ts'], [watcher], { :output => 'target', :noop => true })
        end
      end

      context 'with the :error_to_js option' do
        it 'write the error message as javascript file' do
          expect(runner).to receive(:write_javascript_file).once.with(
            "throw \"#{bad_error_message}\";",
            nil, 'src/bad.ts', 'target', kind_of(Hash)
          )
          runner.run(['src/bad.ts'], [watcher], { :output => 'target', :error_to_js => true })
        end
      end
    end

    context 'without compilation errors' do
      let(:watcher) { Guard::Watcher.new(%r{src/(.+\.(?:ts))$}) }

      context 'without the :noop option' do
        it 'shows a success messages' do
          expect(formatter).to receive(:success).once.with('Successfully generated target/a.js')
          expect(formatter).to receive(:notify).with('Successfully generated target/a.js',
                                                     :title => 'TypeScript results')
          runner.run(['src/a.ts'], [watcher], { :output => 'target' })
        end
      end

      context 'with the :noop option' do
        it 'shows a success messages' do
          expect(formatter).to receive(:success).once.with('Successfully verified target/a.js')
          expect(formatter).to receive(:notify).with('Successfully verified target/a.js',
                                                     :title => 'TypeScript results')
          runner.run(['src/a.ts'], [watcher], { :output => 'target',
                                            :noop => true })
        end
      end

      context 'with the :hide_success option set to true' do
        it 'does not show the success message' do
          expect(formatter).not_to receive(:success).with('Successfully generated target/a.js')
          expect(formatter).not_to receive(:notify).with('Successfully generated target/a.js',
                                                         :title => 'TypeScript results')
          runner.run(['src/x/y/z/a.ts'], [watcher], { :output => 'target',
                                                                :hide_success => true })
        end
      end
    end

    context 'with :hide_success over multiple runs' do
      let(:watcher) { Guard::Watcher.new(%r{src/(.+\.(?:ts))$}) }

      it 'shows the failure message every time' do
        expect(formatter).to receive(:error).twice.with(bad_error_message)
        expect(formatter).to receive(:notify).twice.with(bad_error_message,
                                                         :title => 'TypeScript results',
                                                         :image => :failed,
                                                         :priority => 2)
        2.times { runner.run(['src/bad.ts'], [watcher], { :output => 'target' }) }
      end

      it 'shows the success message only when previous attempt was failure' do
        runner.run(['src/bad.ts'], [watcher], { :output => 'target',
                                                :hide_success => true })

        expect(formatter).to receive(:success).with('Successfully generated target/a.js')
        expect(formatter).to receive(:notify).with('Successfully generated target/a.js',
                                                   :title => 'TypeScript results')
        runner.run(['src/a.ts'], [watcher], { :output => 'target',
                                              :hide_success => true })
      end
    end

    context 'with the :concatenate option' do
      let(:watcher) { Guard::Watcher.new(%r{src/(.+\.(?:ts))$}) }
      it 'should concatenate dependencies if :concatenate is true' do
        runner.run(['src/referencer.ts'], [watcher], { :output => 'target',
                                                       :concatenate => true })
        expect(File).to exist("#{ @project_path }/target/referencer.js")

        File.open("#{ @project_path }/target/referencer.js", "r") do |file|
          found = false
          file.each_line do |line|
            if line =~ /I am the referenced file/
              found = true
              break
            end
          end
          expect(found).to eq(true)
        end
      end

      it 'should separate dependencies if :concatenate is false' do
        runner.run(['src/referencer.ts'], [watcher], { :output => 'target',
                                                       :concatenate => false })
        expect(File).to exist("#{ @project_path }/target/referencer.js")

        File.open("#{ @project_path }/target/referencer.js", "r") do |file|
          found = false
          file.each_line do |line|
            if line =~ /I am the referenced file/
              found = true
              break
            end
          end
          expect(found).to eq(false)
        end
      end
    end
  end

  describe '#remove' do
    let(:watcher) { Guard::Watcher.new(%r{src/.+\.(?:ts)$}) }

    before do
      expect(File).to receive(:exists?).with('target/a.js').and_return true
      expect(File).to receive(:exists?).with('target/b.js').and_return true
    end

    it 'removes the files' do
      runner.run(['src/a.ts', 'src/b.ts'], [watcher], :output => 'target')
      expect(FileUtils).to receive(:remove_file).with('target/a.js')
      expect(FileUtils).to receive(:remove_file).with('target/b.js')
      runner.remove(['src/a.ts', 'src/b.ts'], [watcher], { :output => 'target' })
    end

    it 'shows a notification' do
      runner.run(['src/a.ts', 'src/b.ts'], [watcher], :output => 'target')
      expect(formatter).to receive(:success).once.with('Removed target/a.js, target/b.js')
      expect(formatter).to receive(:notify).with('Removed target/a.js, target/b.js',
                                                 :title => 'TypeScript results')
      runner.remove(['src/a.ts', 'src/b.ts'], [watcher], { :output => 'target' })
    end
  end
end