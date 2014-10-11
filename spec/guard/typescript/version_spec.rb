require 'spec_helper'

describe Guard::TypeScriptVersion do
  describe 'VERSION' do
    it 'defines the version' do
      Guard::TypeScriptVersion::VERSION.should match /\d+.\d+.\d+/
    end
  end
end