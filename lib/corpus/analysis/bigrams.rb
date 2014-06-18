module Corpus

  module Analysis

    ##
    # Bigram analysis.
    #
    class Bigrams
      include Utils
      include Enumerable

      REJECT_BIGRAMS = %w{ye yo n't d'n sh th ha ah la sa}

      # Initialize Bigram analysis instance.
      #
      # analysis - The main Analysis instance.
      #
      def initialize(directory)
        @directory = directory
        @table = {}
        @index = Hash.new{ |h,k| h[k] = [] }
      end

      #
      attr :directory

      # Get list of bigrams for a given word.
      def [](word)
        @index[word]
      end

      # Add a bigram to the table. If it is already present
      # just count the additional file that contatins it.
      def add(word1, word2, file=nil)
        key = [word1,word2]
        if @table.key?(key)
	        @table[key].file!(file) if file
        else
          bigram = Bigram.new(word1, word2)
          @table[key] = bigram
	        @table[key].file!(file)
          @index[word1] << word2
        end
      end

      # Assign birgram.
      #def []=(word1, word2)
      #  @table[word1] = word2
      #end

      #
      # List of all bigrams from all files.
      #
      def list
        @table.keys
      end

      # 
      def to_a
        @table.values
      end

      # Iterate over bigram table.
      def each_entry(&b)
        @table.each(&b)
      end

      # Iterate over each bigram as an instance of Bigram.
		  def each
		    @table.each do |pair, bigram|
          yield(bigram)
		    end
		  end

      #
      def size
        @table.size
      end

      # Total number of bigrams.
      def total
        @total ||= (
          tally = 0
          each do |b|
            tally += b.count
          end
          tally
        )
      end

      # Get a list of second words of bigrams matching the given
      # first word.
      def matching_bigrams(word1)
        list = @index[word1]
        list.map{ |word2| @table[[word1,word2]] }
      end

      # Probability of bigram's occurance in the corpus.
      def probability(word1, word2=nil)
        bigram = (Bigram === word1 ? word1 : get(word1, word2))
        BigDecimal.new(bigram.count) / total #size
      end

      # Probability of bigram's occurance in the corpus.
      def file_probability(word1, word2=nil)
        bigram = (Bigram === word1 ? word1 : get(word1, word2))
        BigDecimal.new(bigram.files.size) / analysis.files.size
      end

      # File weighted probablity of the bigram appearing in the corpus.
      #
      # TODO: Don't count file probability.
      def score(word1, word2=nil)
        weight = 1 #file_probability(word1, word2)
        weight * probability(word1, word2)
      end

      # Get a bigram given both words.
      def get(word1, word2)
        @table[[word1,word2]]
      end

      #
      def to_cache
        { 'index' => @index, 'table' => @table }
      end

      #
      def from_cache(cache)
        @index = cache['index']
        @table = cache['table']
      end

      # Sace file counting words and bigrams.
      def scan
        $stderr.print "[bigrams] "

        last = nil

        bigram_files.each do |file|
          $stderr.print "."

          text = File.read(file).gsub("\n", " ")
          states = text.split(/[.,:;?!()"]\s*/)

          states.each do |state|
            state.scan(WORD) do |word|
              word = normalize(word)
              if valid_word?(word)
		            if last && good_bigram?(word)
                  add(last, word, file)
		            end
		            last = word
              else
                last = nil
              end
            end
            last = nil
          end
          last = nil
        end

        $stderr.puts
      end

      # Check if a given word should be considered an acceptable bigram.
      def good_bigram?(word)
        return false if REJECT_BIGRAMS.include?(word)
        return false if word.size < 2
        true
      end

      #
      def files
        @files ||= Dir.glob(File.join(directory, 'corpus', '**', '*.txt'))
      end

      alias bigram_files files

    end

  end
end
