# frozen_string_literal: true

module Codeowners
  # This class is responsible for print the reports
  class Reporter
    LABELS = {
      missing_ref: 'No owner defined',
      useless_pattern: 'Useless patterns',
      invalid_owner: 'Invalid owner',
      unrecognized_line: 'Unrecognized line'
    }.freeze

    class << self
      def print_delimiter_line(error_type)
        raise ArgumentError, "unknown error type '#{error_type}'" unless LABELS.key?(error_type)

        print('-' * 30, LABELS[error_type], '-' * 30)
      end

      def print_error(error_type, inconsistencies, meta)
        case error_type
        when :invalid_owner then print("#{inconsistencies} MISSING: #{meta.join(', ')}")
        else print(inconsistencies.to_s)
        end
      end

      def print(*args)
        puts(*args)
      end
    end
  end
end
