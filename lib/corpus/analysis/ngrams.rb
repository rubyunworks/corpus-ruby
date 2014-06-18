module Corpus

  module Analysis

    ##
    # N-Gram statistical analysis.
    #
    class NGrams
      include Enumerable
      include Utils

      #
      REJECT_NGRAMS = %w{ye yo n't d'n sh th ha ah la sa}

      # These words are so common that they provide poor indication
      # of any n-gram patters, so they are excluded if occuring first.
      INVALID_FIRST_WORDS = %{the a an of and}

      # These words are so common that they provide poor indication
      # of any n-gram patters, so they are excluded if occuring last.
      INVALID_FINAL_WORDS = %{the a an of and}

      #
      def initialize(directory, options={})
        @directory = directory
        @lexicon   = Lexicon.instance(directory)
        @number    = options[:n] || 2
        @table     = Hash.new{ |h,k| h[k] = 0 }
      end

      # 
      attr :directory

      # Table of n-grams maps the n-gram to it's absolute count in the corpus.
      attr :table

      # The "n" in "n-grams".
      attr :number

      # Total count of all n-grams.
      attr :total

      #
      attr :lexicon

      #
      def scan
        $stderr.print "[ngrams]"

        files.each do |file|
          $stderr.print "."
          text = File.read(file)

          range.each do |num|
            stack = [nil] * num
            text.scan(WORD) do |word|
              word = normalize(word)
              next unless valid_ngram?(word)
              stack.shift  # remove top item
              stack.push(word)
              next unless stack.first
              next unless valid_ngram_stack?(stack)
              table[stack.dup] += 1
            end
          end
        end

        $stderr.puts

        @total = sum(table.values)
      end

      #
      def range
        if (Range === number)
          number
        else
          number..number
        end
      end

      #
      def empty?
        @table.empty?
      end

      # Sort hightest to lowest.
      def sorted_by_rank(join=false)
        list = []
        if join
          table.each do |parts, count|
            list << [count, parts.join(' ')]
          end
        else
          table.each do |parts, count|
            list << [count, *parts]
          end
        end
        #list.sort{ |a,b| b.first <=> a.first }
        list.sort_by{ |x| x.first }.reverse
      end

      #
      def each(&block)
        @table.each(&block)
      end

      #
      def total
        @total
      end

      #
      def max_count
        @max_count ||= table.values.max
      end

    private

      #
      def files
        @files ||= Dir[File.join(directory, 'corpus', '**', '*.txt')]
      end

      #
      #def pieces(word)
      #  list = []
      #  word.length.times do |i|
      #    suffix = word[i..-1]
      #    prefix = word[0..i]
      #    list << ((suffix == word ? "" : "-") + suffix)
      #    list << (prefix + (prefix == word ? "" : "-"))
      #  end
      #  list.uniq
      #end

      # Sum all the elements of an array.
      def sum(array)
        t = 0
        array.each do |v|
          t += v
        end
        t
      end

      #
      def product(*array_of_array)
        first, *last = *array_of_array
        first.product(*last)
      end

      # Check if a given word should be considered an acceptable n-gram.
      def valid_ngram?(word)
        return false unless valid_word?(word)
        return false if word.size < 1  # 2
        return false if REJECT_NGRAMS.include?(word)
        true
      end

      # Check if the n-gram taken as a whole is acceptable.
      def valid_ngram_stack?(stack)
        return false if INVALID_FIRST_WORDS.include?(stack.first)
        return false if INVALID_FINAL_WORDS.include?(stack.last)
        return true
      end

    end

  end

end
