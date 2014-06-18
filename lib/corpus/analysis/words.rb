module Corpus

  module Analysis

    ##
    # Word analysis.
    #
    class Words
      include Enumerable
      include Utils

      # Initialize Words analysis instance.
      #
      # analysis - The main Analysis instance.
      #
      def initialize(directory)
        @directory = directory
        @lexicon = Lexicon.instance(directory)
        @table = {}
      end

      #
      attr :directory

      #
      attr :lexicon

      # Lookup word.
      def [](spelling)
        @table[spelling]
      end

      # Assign word.
      def []=(spelling, word)
        @table[spelling] = word
      end

      #
      def has_word?(spelling)
        @table.key?(spelling)
      end

      # List of word spellings.
      #
      # Return [Array<String>]
      def list
        @table.keys  # values
      end

      # List of Word instances.
      #
      # Return [Array<Word>]
      def to_a
        @table.values
      end

      # Is the word table empty?
      #
      # Return [Boolean]
      def empty?
        @table.empty?
      end

      #
      def size
        @table.size
      end

      # Iterate over each word as an instance of Word.
      def each
        @table.each do |_, word|
          yield(word)
        end
      end

      # Iterate over the underlying hash table.
      def each_entry(&b)
        @table.each(&b)
      end

      # Total number of words.
      def total
        @total ||= (
          tally = 0
          each do |w|
            tally += w.count
          end
          tally
        )
      end

      # Cached: List of words sorted by weighted probability.
      #
      # Returns [Array<Word>]
      def sorted_by_weight
        @_sorted_by_weight ||= (
          @table.values.sort_by { |w| weighted_probability(w) }.reverse
        )
      end

      # Get the top weighted words.
      def top_weighted(max)
        nsize = necessary_words.size
        sorted_by_weight.take(max - nsize) | necessary_words
      end

      ## Return a list of words and their scores.
      ##
      ## Returns [Hash]
      #def scoresheet(max=nil)
      #  a = []
      #  # go over each word and get score
      #  each do |w|
      #    a << [w.to_s, score(w)]
      #  end
      #  # get necessary words and their scores
      #  n = necessary_scores(a)
      #  # take maximum number of words wanted
      #  if max
      #    a = a.sort_by{ |_, s| s }.reverse
      #    a = a.take(max.to_i)
      #  end
      #  # remove n's trailing words to ensure size, but have to deal with dups too
      #  #a = a.take(a.size - n.size)
      #  # add necessary words
      #  a | n
      #end

      # Get word rank. The rank is the index of the ordered list of
      # of words sorted by score.
      def rank!(word)
        sorted_by_weight.each_with_index do |w, i|
          return i + 1 if w.spelling == word.to_s
        end
        return -1
      end

      # The score is the weighted probability of the word appearing in the
      # corpus normalized to an integer by taking the inverse log and multipying
      # it by 65536. The higher the number, the more likely it is to occur.
      # 
      # NOTE: We are making the assumption that no word will ever occur more
      #       than 10% of the time.
      #
      # Returns [Integer]
      #def score(word)
      #  p = weighted_probability(word)
      #  l = Math.log10(p / 10)
      #  i = -(65536 / l).to_i
      #end

      # Weighted odds of the word appearing in the corpus.
      #
      # TODO: Rename to `probability`.
      #
      # Return [BigDecimal]
      def weighted_probability(word)
        word = (Word === word ? word : get(word))

        p = BigDecimal.new(1)
        p = p * probability(word)
        p = p * file_probability(word, 1)
        #p = p * lexicon_weight(word)
        #p = p * weight_length(word)
        #p = p * weight_stem(word)
        #p = p * weight_plural(word)
        p
      end

      # Probability of word's occurance in the entire corpus.
      #
      # TODO: Rename to `total_probability`.
      #
      # Return [BigDecimal]
      def probability(word)
        word = (Word === word ? word : get(word))
        BigDecimal.new(word.count) / total
      end

      # Probability of a word occuring in a file.
      #
      # word      - a word [Word,String]
      # threshold - number of times the word must occur in the file
      #
      # Returns [BigDecimal]
      def file_probability(word, threshold=0)
        word = (Word === word ? word : get(word))
        n = 1  # at least one
        word.files.each do |f, c|
          n += 1 if c > threshold
        end
        BigDecimal.new(n) / corpus_files.size
      end

=begin
      # If a word is in the lexicon then it is not weighted down. If the word
      # has a stem ending and the stem is in the lexicon it is weighted only
      # slighly at 0.9. Otherwise the word is weighed down heavily at 0.01.
      #
      # word - word [Word,String]
      #
      # Returns [Float]
      def lexicon_weight(word)
        spelling = word.to_s
        return 1.0 if lexicon.member?(spelling)
        STEM_ENDINGS.each do |e|
          stem = spelling.chomp(e)
          return 0.9 if lexicon.member?(stem)
        end
        return 0
      end

      # Weight words based on size. Smaller the word, the higher the score.
      def weight_length(word)
        size = word.to_s.size
        10.0 / size
      end

      # Weight by half if word has a common stem, e.g. `ing`, `es`, etc.
      def weight_stem(word)
        return 0.5 if stem?(word)
        return 1.0
      end
=end

      #
      #def weight_plural(word)
      #  return 0.6 if plural?(word)
      #  return 1.0
      #end

      #
      #def stem?(word)
      #  STEM_ENDINGS.any?{ |e| word.to_s.end_with?(e) }
      #end

      # Get Word instance for a given word spelling.
      def get(spelling)
        @table[spelling]
      end

      #
      #def to_cache
      #  { 'table' => @table }
      #end

      #
      #def from_cache(cache)
      #  @table = cache['table']
      #end

      # If a word ends in one of these it is not considerd a *stem word*.
      STEM_ENDINGS = %w{s es ed er ing able ly}

      # Scan files counting words.
      def scan
        $stderr.print "[words] "

        files.each do |file|
          if $DEBUG
            $stderr.print "\n[scan] #{file}"
          else
            $stderr.print "."
          end

          text   = File.read(file).gsub("\n", " ")
          states = text.split(/[.,:;?!()"]\s*/)

          states.each do |state|
            state.scan(WORD) do |word|
              word = normalize(word)
              if valid_word?(word)
		            self[word] ||= Word.new(word)
		            self[word].file!(file)
              end
            end
          end
        end

        $stderr.puts
      end

      # Determine if a word is valid. Some basic heuristics are used here,
      # but a word is not valid unless it is in the lexicon.
      #
      # TODO: Make stem ending more robust.
      #
      def valid_word?(spelling)
        return false unless super(spelling)

        return true if lexicon.member?(spelling)

        STEM_ENDINGS.each do |e|
          stem = spelling.chomp(e)
          return true if lexicon.member?(stem)
        end

        false
      end

      # Returns [Array<Word>].
      def necessary_words
        @necessary_words ||= load_necessary_words
      end

      # Load the necessary words, ensuring that are in the corpus.
      def load_necessary_words
        necessary_words = []

        necessary_spellings.each do |spelling|
          if @table.key?(spelling)
            necessary_words <<  @table[spelling]
          else
            $stderr.puts "Warning! #{spelling} is a necessary word but it is not in the corpus."
          end
        end

        necessary_words
      end

      # Read the necessity.txt file and parse out the words.
      def necessary_spellings
        spellings = []
        if necessary_file
          File.readlines(necessary_file).each do |line|
            line.strip!
            spellings << line unless line == ""
          end
        end
        spellings
      end

      # Words that must be included need to be put in a lexicon file
      # named `necessary.txt`.
      def necessary_file
        @necessary_file ||= (
          file = File.join(directory, 'lexicon', "{N,n}ecessary.txt")
          Dir.glob(file).first
        )
      end

      # Corpus files.
      def files
        @files ||= Dir[File.join(directory, 'corpus', '**', '*.txt')]
      end
      alias corpus_files files

    end

  end

end
