require 'ruby-typescript'

module Guard
  class TypeScript
    module Runner
      class << self

        attr_accessor :last_run_failed

        # The TypeScript runner handles the TypeScript compilation,
        # creates nested directories and the output file, writes the result
        # to the console and triggers optional system notifications.
        #
        # @param [Array<String>] files the spec files or directories
        # @param [Array<Guard::Watcher>] watchers the Guard watchers in the block
        # @param [Hash] options the options for the execution
        # @option options [String] :input the input directory
        # @option options [String] :output the output directory
        # @option options [Boolean] :shallow do not create nested directories
        # @option options [Boolean] :hide_success hide success message notification
        # @option options [Boolean] :noop do not generate an output file
        # @option options [Boolean] :source_map generate the source map files
        # @return [Array<Array<String>, Boolean>] the result for the compilation run
        #
        def run(files, watchers, options = { })
          notify_start(files, options)
          changed_files, errors = compile_files(files, watchers, options)
          notify_result(changed_files, errors, options)

          [changed_files, errors.empty?]
        end

        # The remove function deals with TypeScript file removal by
        # locating the output javascript file and removing it.
        #
        # @param [Array<String>] files the spec files or directories
        # @param [Array<Guard::Watcher>] watchers the Guard watchers in the block
        # @param [Hash] options the options for the removal
        # @option options [String] :output the output directory
        # @option options [Boolean] :shallow do not create nested directories
        #
        def remove(files, watchers, options = { })
          removed_files = []
          directories   = detect_nested_directories(watchers, files, options)

          directories.each do |directory, scripts|
            scripts.each do |file|
              javascript = javascript_file_name(file, directory)
              if File.exists?(javascript)
                FileUtils.remove_file(javascript)
                removed_files << javascript
              end
            end
          end

          if removed_files.length > 0
            message = "Removed #{ removed_files.join(', ') }"
            Formatter.success(message)
            Formatter.notify(message, :title => 'TypeScript results')
          end
        end

        private

        # Generates a start compilation notification.
        #
        # @param [Array<String>] files the generated files
        # @param [Hash] options the options for the execution
        # @option options [Boolean] :noop do not generate an output file
        #
        def notify_start(files, options)
          message = options[:message] || (options[:noop] ? 'Verify ' : 'Compile ') + files.join(', ')
          Formatter.info(message, :reset => true)
        end

        # Compiles all TypeScript files and writes the JavaScript files.
        #
        # @param [Array<String>] files the files to compile
        # @param [Array<Guard::Watcher>] watchers the Guard watchers in the block
        # @param [Hash] options the options for the execution
        # @return [Array<Array<String>, Array<String>] the result for the compilation run
        #
        def compile_files(files, watchers, options)
          errors        = []
          changed_files = []
          directories   = detect_nested_directories(watchers, files, options)

          directories.each do |directory, scripts|
            scripts.each do |file|
              begin
                js, map = compile(file, directory, options)
                if options[:noop]
                  if File.exists?(js)
                    FileUtils.remove_file(js)
                  end
                  if map and File.exists?(map)
                    FileUtils.remove_file(map)
                  end
                end
                changed_files << js << map
              rescue => e
                error_message = file + ': ' + e.message.to_s

                if options[:error_to_js]
                  js_error_message = "throw \"#{ error_message }\";"
                  changed_files << write_javascript_file(js_error_message, nil, file, directory, options)
                end

                errors << error_message
                Formatter.error(error_message)
              end
            end
          end
          [changed_files.flatten.compact, errors]
        end

        # Compile the TypeScript and generate the source map.
        #
        # @param [String] filename the TypeScript file name
        # @param [Hash] options the options for the execution
        # @option options [Boolean] :source_map generate the source map files
        # @option options [Boolean] :concatenate concatenate dependencies into one file
        # @return [Array<String, String>] the JavaScript filename and the source map filename
        #
        def compile(filename, directory, options)
          options = options.clone
          keys = [:source_map, :source_root, :target, :module]
          values = options.values_at(*keys)
          compile_options = Hash[keys.zip(values)]
          output_filename = javascript_file_name(filename, directory)
          if options[:concatenate]
            compile_options[:output] = output_filename
          else
            compile_options[:output_dir] = File.dirname(output_filename)
          end

          result = ::TypeScript.compile_file(filename, compile_options)
          if options[:source_map]
            js, map = result[:js], result[:source_map]
          else
            js  = result[:js]
          end
          [js, map]
        end

        # Analyzes the CoffeeScript compilation output and creates the
        # nested directories and writes the output file.
        #
        # @param [String] js the JavaScript content
        # @param [String] map the source map content
        # @param [String] file the CoffeeScript file name
        # @param [String] directory the output directory
        # @param [Hash] options the options for the execution
        # @option options [Boolean] :noop do not generate an output file
        # @return [String] the JavaScript file name
        #
        def write_javascript_file(js, map, file, directory, options)
          directory = Dir.pwd if !directory || directory.empty?
          filename = javascript_file_name(file, directory)

          return filename if options[:noop]

          if options[:source_map]
            map_name = filename + '.map'
            js += "\n/*\n//@ sourceMappingURL=#{File.basename(map_name)}\n*/\n"
          end

          FileUtils.mkdir_p(File.expand_path(directory)) if !File.directory?(directory)
          File.open(File.expand_path(filename), 'w') { |f| f.write(js) }

          if options[:source_map]
            File.open(File.expand_path(map_name), 'w') { |f| f.write(map) }
            [filename, map_name]
          else
            filename
          end
        end

        # Calculates the output filename from the typescript filename and
        # the output directory
        #
        # @param [string] filename the TypeScript file name
        # @param [String] directory the output directory
        #
        def javascript_file_name(filename, directory)
          File.join(directory, File.basename(filename.gsub(/((?:js\.)?(?:ts))$/, 'js')))
        end

        # Detects the output directory for each TypeScript file. Builds
        # the product of all watchers and assigns to each directory
        # the files to which it belongs to.
        #
        # @param [Array<Guard::Watcher>] watchers the Guard watchers in the block
        # @param [Array<String>] files the TypeScript files
        # @param [Hash] options the options for the execution
        # @option options [String] :output the output directory
        # @option options [Boolean] :shallow do not create nested directories
        #
        def detect_nested_directories(watchers, files, options)
          return { options[:output] => files } if options[:shallow]

          directories = { }

          watchers.product(files).each do |watcher, file|
            if matches = file.match(watcher.pattern)
              if options[:output]
                target = matches[1] ? File.join(options[:output], File.dirname(matches[1])).gsub(/\/\.$/, '') : options[:output] || File.dirname(file)
              else
                target = File.dirname(file)
              end
              if directories[target]
                directories[target] << file
              else
                directories[target] = [file]
              end
            end
          end

          directories
        end

        # Writes console and system notifications about the result of the compilation.
        #
        # @param [Array<String>] changed_files the changed JavaScript files
        # @param [Array<String>] errors the error messages
        # @param [Hash] options the options for the execution
        # @option options [Boolean] :hide_success hide success message notification
        # @option options [Boolean] :noop do not generate an output file
        #
        def notify_result(changed_files, errors, options = { })
          if !errors.empty?
            self.last_run_failed = true
            Formatter.notify(errors.join("\n"), :title => 'TypeScript results', :image => :failed, :priority => 2)
          elsif !options[:hide_success] || last_run_failed
            self.last_run_failed = false
            message = "Successfully #{ options[:noop] ? 'verified' : 'generated' } #{ changed_files.join(', ') }"
            Formatter.success(message)
            Formatter.notify(message, :title => 'TypeScript results')
          end
        end

      end
    end
  end
end