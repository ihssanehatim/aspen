require 'strscan'

module Aspen
  class Lexer

    STRING_CAPTURE    = /(["'])(?:(?=(\\?))\2.)*?\1/
    # From https://stackoverflow.com/questions/171480/regex-grabbing-values-between-quotation-marks

    NUMBER_CAPTURE    = /([\d,]+\.?\d+)/

    PASCAL_CASE       = /^([A-Z][a-zA-Z0-9]+)/
    LABEL_PASCAL_CASE = /^(:[A-Z][a-zA-Z0-9]+)/

    CONTENT_REGEX     = /[[[:alnum:]][[:blank:]]"'&_,\-\–\—\!\.\/\\\?\$]+/
    LABELED_NODE      = /^([A-Z][a-zA-Z0-9]+): (#{CONTENT_REGEX})\)/

    def self.tokenize(code, env={})
      new.tokenize(code, env)
    end

    def tokenize(code, env={})
      scanner = StringScanner.new(code)
      tokens = []

      environment = Discourse.assert(env)
      grammar = environment.grammar

      until scanner.eos?
        # puts "tokens (6): #{tokens.last(6).inspect}"
        # puts "\n(#{state}) stack: #{stack}"
        # puts "grammar: #{grammar.inspect}"

        # Match custom grammars
        if grammar && scanner.beginning_of_line?
          line = scanner.scan(/^.*$/)
          if grammar.match?(line)
            tokens << [:CUSTOM_GRAMMAR_STATEMENT, line]
            next
          else
            scanner.unscan # reset pointer to beginning of line
          end
        end

        # If the line ends with :, it's starting a list.
        if scanner.beginning_of_line?
          line = scanner.scan(/^.*$/)
          if line.match? /:$/
            tokens << [:PREPARE_START_LIST]
          end
          scanner.unscan
        end

        # Standard Aspen syntax
        case state
        when :default then
          if scanner.scan(/\(/)
            tokens << [:OPEN_PARENS]
            push_state :node
          elsif scanner.scan(/\[/)
            tokens << [:OPEN_BRACKETS]
            push_state :edge
          elsif scanner.scan(/(:\s*\n)/) # Colon, any whitespace, newline
            tokens << [:START_LIST, scanner.matched]
            push_state :list
          elsif scanner.scan(/\./)
            tokens << [:END_STATEMENT, scanner.matched]
          elsif scanner.scan(/\s/)
            # NO OP
          elsif scanner.scan(/#.*$/)
            tokens << [:COMMENT, scanner.matched.gsub(/#\s*/, '')]
          else
            no_match(scanner, state)
          end

        when :node then
          # Removed Cypher form for now. Un   comment the next 3 lines
          # to start working on it.
          #
          # if scanner.scan(LABEL_PASCAL_CASE)
          #   tokens << [:LABEL, scanner.matched]
          #   push_state :hash
          if scanner.match?(LABELED_NODE)
            push_state :node_labeled
          elsif scanner.scan(/\n/) && stack == [:list, :node]
            # If we're inside a list node and we encounter a newline,
            # pop :node so we can return to the :list state.
            scanner.unscan
            pop_state
          elsif scanner.scan(CONTENT_REGEX)
            tokens << [:CONTENT, scanner.matched.strip]
          elsif scanner.scan(/[\:]/)
            tokens << [:SEPARATOR, scanner.matched]
          elsif scanner.scan(/\(/)
            tokens << [:OPEN_PARENS]
            push_state :label
          elsif scanner.scan(/\)/)
            tokens << [:CLOSE_PARENS]
            pop_state
          else
            no_match(scanner, state)
          end

        when :node_labeled
          if scanner.scan(PASCAL_CASE)
            tokens << [:LABEL, scanner.matched]
            pop_state # Back to Node
          else
            no_match(scanner, state)
          end

        when :edge then
          if scanner.scan(/[[[:alpha:]]\s]+/)
            tokens << [:CONTENT, scanner.matched.strip]
          elsif scanner.scan(/\]/)
            tokens << [:CLOSE_BRACKETS]
            pop_state
          else
            no_match(scanner, state)
          end

        when :hash then
          if scanner.scan(/\{/)
            tokens << [:OPEN_BRACES]
          elsif scanner.scan(/[[[:alpha:]]_]+/)
            tokens << [:IDENTIFIER, scanner.matched]
          elsif scanner.scan(/[\,\:]/)
            tokens << [:SEPARATOR, scanner.matched]
          elsif scanner.scan(STRING_CAPTURE)
            tokens << [:STRING, scanner.matched]
          elsif scanner.scan(NUMBER_CAPTURE)
            tokens << [:NUMBER, scanner.matched]
          elsif scanner.scan(/\}/)
            tokens << [:CLOSE_BRACES]
            pop_state
          elsif scanner.scan(/\s+/)
            # NO OP
          else
            no_match(scanner, state)
          end

        when :list then
          if scanner.scan(/([\-\*\+])/) # -, *, or + (any allowed by Markdown)
            tokens << [:BULLET, scanner.matched]
            push_state :node
          elsif scanner.scan(/\n\n/)
            tokens << [:END_LIST]
            pop_state
          elsif scanner.scan(/\s/)
            # NO OP
          else
            no_match(scanner, state)
          end

        when :label
          if scanner.scan(PASCAL_CASE)
            tokens << [:CONTENT, scanner.matched]
          elsif scanner.peek(1).match?(/\)/)
            pop_state # Go back to :node and let :node pop state
          else
            no_match(scanner, state)
          end

        else # No state match
          raise Aspen::LexError, "There is no matcher for state #{state.inspect}."
        end
      end

      tokens
    end

    def stack
      @stack ||= []
    end

    def state
      stack.last || :default
    end

    def push_state(state)
      stack.push(state)
    end

    def pop_state
      stack.pop
    end

    private

    def no_match(scanner, state)
      raise Aspen::LexError,
              Aspen::Errors.messages(:unexpected_token, scanner, state)
    end

  end
end
