module Guard
  class TypeScript

    # The inspector verifies of the changed paths are valid
    # for Guard::TypeScript.
    #
    module Inspector
      class << self

        # Clean the changed paths and return only valid
        # TypeScript files.
        #
        # @param [Array<String>] paths the changed paths
        # @param [Hash] options the clean options
        # @option options [String] :missing_ok don't remove missing files from list
        # @return [Array<String>] the valid spec files
        #
        def clean(paths, options = {})
          paths.uniq!
          paths.compact!
          paths.select { |p| typescript_file?(p, options) }
        end

        private

        # Tests if the file is valid.
        #
        # @param [String] path the file
        # @param [Hash] options the clean options
        # @option options [String] :missing_ok don't remove missing files from list
        # @return [Boolean] when the file valid
        #
        def typescript_file?(path, options)
          path =~ /\.(?:ts)$/ && (options[:missing_ok] || File.exists?(path))
        end

      end
    end
  end
end