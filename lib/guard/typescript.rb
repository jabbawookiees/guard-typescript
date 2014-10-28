require 'guard'
require 'guard/guard'
require 'guard/watcher'

module Guard
  # The TypeScript guard that gets notifications about the following
  # Guard events: `start`, `stop`, `reload`, `run_all` and `run_on_change`.
  #
  class TypeScript < Guard
    autoload :Formatter, 'guard/typescript/formatter'
    autoload :Inspector, 'guard/typescript/inspector'
    autoload :Runner, 'guard/typescript/runner'

    DEFAULT_OPTIONS = {
        :shallow      => false,
        :hide_success => false,
        :error_to_js  => false,
        :all_on_start => false,
        :source_map   => false
    }

    # Initialize Guard::TypeScript.
    #
    # @param [Array<Guard::Watcher>] watchers the watchers in the Guard block
    # @param [Hash] options the options for the Guard
    # @option options [String] :input the input directory
    # @option options [String] :output the output directory
    # @option options [Boolean] :concatenate combine dependencies into files
    # @option options [Boolean] :shallow do not create nested directories
    # @option options [Boolean] :hide_success hide success message notification
    # @option options [Boolean] :all_on_start generate all JavaScripts files on start
    # @option options [Boolean] :source_map generate the source map files
    #
    def initialize(watchers = [], options = {})
      watchers = [] if !watchers
      defaults = DEFAULT_OPTIONS.clone

      if options[:input]
        defaults.merge!({ :output => options[:input] })
        watchers << ::Guard::Watcher.new(%r{^#{ options[:input] }/(.+\.(?:ts))$})
      end

      super(watchers, defaults.merge(options))
    end

    # Gets called once when Guard starts.
    #
    # @raise [:task_has_failed] when stop has failed
    #
    def start
      run_all if options[:all_on_start]
    end

    # Gets called when all files should be regenerated.
    #
    # @raise [:task_has_failed] when stop has failed
    #
    def run_all
      run_on_modifications(Watcher.match_files(self, Dir.glob('**{,/*/**}/*.ts')))
    end

    # Gets called when watched paths and files have changes.
    #
    # @param [Array<String>] paths the changed paths and files
    # @raise [:task_has_failed] when stop has failed
    #
    def run_on_modifications(paths)
      changed_files, success = Runner.run(Inspector.clean(paths), watchers, options)

      throw :task_has_failed unless success
    end

    # Called on file(s) deletions that the Guard watches.
    #
    # @param [Array<String>] paths the deleted files or paths
    # @raise [:task_has_failed] when run_on_change has failed
    #
    def run_on_removals(paths)
      Runner.remove(Inspector.clean(paths, :missing_ok => true), watchers, options)
    end
  end
end