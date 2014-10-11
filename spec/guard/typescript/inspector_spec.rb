require 'spec_helper'

describe Guard::TypeScript::Inspector do
  let(:inspector) { Guard::TypeScript::Inspector }

  describe 'clean' do
    it 'removes duplicate files' do
      File.should_receive(:exists?).with("a.ts").and_return true
      File.should_receive(:exists?).with("b.ts").and_return true
      inspector.clean(['a.ts', 'b.ts'])
               .should == ['a.ts', 'b.ts']
    end

    it 'remove nil files' do
      File.should_receive(:exists?).with("a.ts").and_return true
      File.should_receive(:exists?).with("b.ts").and_return true
      inspector.clean(['a.ts', 'b.ts', nil])
               .should == ['a.ts', 'b.ts']
    end

    describe 'without the :missing_ok option' do
      it 'removes non-typescript files that do not exist' do
        File.should_receive(:exists?).with("a.ts").and_return true
        File.should_receive(:exists?).with("c.ts").and_return true
        File.should_receive(:exists?).with("doesntexist.ts").and_return false
        inspector.clean(['a.ts', 'b.txt', 'c.ts', 'doesntexist.ts'])
                 .should == ['a.ts', 'c.ts']
      end
    end

    describe 'with the :missing_ok options' do
      it 'removes non-typescript files' do
        inspector.clean(['a.ts', 'b.txt', 'c.ts', 'doesntexist.ts'], { :missing_ok => true })
                 .should == ['a.ts', 'c.ts', 'doesntexist.ts']
      end
    end

  end
end