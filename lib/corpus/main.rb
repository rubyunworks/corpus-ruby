module Corpus

  #
  #
  def self.new(directory)
    Main.new(directory)
  end

  ##
  #
  #
  class Main

    # Default maximum word count.
    # TODO: Remove this default limit?
    MAX_WORDS = 50000

    # The taphoic keyboard can show up to eight word predictions.
    MAX_BIGRAMS = 8

    #
    #def self.scan(directory)
    #  c = new(directory)
    #  c.scan
    #  c
    #end

    #
    # 
    #
    def initialize(directory, options={})
      raise "No such corpus directory: #{directory}" unless File.directory?(directory)

      @directory = directory

      @max_words   = options[:max] || MAX_WORDS
      @max_bigrams = options[:bigrams] || MAX_BIGRAMS

      #@analysis  = Analysis.new(directory)
    end

    #
    attr :max_words

    #
    attr :max_bigrams

    # Words that must be included need to be put in a dictionary file
    # named `necessary.txt`.
    def necessary_file
      @necessary_file ||= (
        file = File.join(Dir.pwd, 'data', 'dictionary', "{N,n}ecessary.txt")
        Dir.glob(file).first
      )
    end

    #
    #
    #
    def analysis
      @analysis ||= Analysis.new(directory)
    end

    #
    #def scan
    #  #if cache?
    #  #  @analysis.load_cache(cache_file)
    # #else
    #    @analysis.scan
    #  #  @analysis.save_cache(cache_file)
    #  #end
    #end

    # DEPRECATE
    def cache_file
      File.join(directory, '.corpus')
    end

    ##
    ## Does the corpus have a cached analysis?
    ##
    def cache?
      File.directory?(cache_file)
    end

    # The directory which contains the text files comprising the corpus.
    attr :directory

    # Instance of Analysis.
    #def analysis
    #  @analysis
    #end

    # Run analysis on entire corpus.
    #def analyze
    #  @analysis = Analysis.new(directory)
    #  @analysis.scan
    #  #@analysis.save!
    #end

    #
    def files
      analysis.files
    end

    #
    def words
      analysis.words
    end

    #
    def bigrams
      analysis.bigrams
    end

    #
    def letters
      analysis.letters
    end

    #
    def ngrams
      analysis.ngrams
    end

    #
    def evolve
      require_relative 'ga'

      analysis  # prime corpus

      #population = (0..9).map do |i|
      #  Layout.random(self)
      #end

      ga = GeneticAlgorithm.new(Layout.population(self))

      1000.times do |i| 
        $stderr.print "%2s) " % [i]
        ga.evolve

        best = ga.best_fit.first
        puts best.score
        puts best
        puts
      end
    end

    #
    def search
      analysis  # prime corpus

      timer = Time.now
      counter = 1

      @score = 0
      @best  = nil

      loop do
        layout = Layout.random(self)
        score  = layout.score

        if score > @score
          @best  = layout
          @score = score

          puts "#{counter})"
          puts layout
          puts "Score: #{score}"
          puts "Speed: %s s" % [(Time.now - timer) / counter]
          puts
        end

        counter += 1
      end
    end

    # Spelling hierarchy.
    def hierarchy
      @hierarchy ||= build_hierarchy
    end

    # Build the spelling hierarchy.
    def build_hierarchy
      root = LetterNode.new(nil)

      # TODO: Limit word table to 50,000 highest scoring words

      words.each do |word|
        wl = root
        word.spelling.each_char do |letter|
          wl = wl.add(letter, word.count)
        end
        wl.word!(word.count)
      end

      root
    end


    # Output bigrams.
    def output_bigrams(opts={})
      output = opts[:out] || $stdout

      bigram_list = []

      bigrams.each do |b|
        bigram_list << [bigrams.score(b), b.word1, b.word2]
      end

      bigram_list = bigram_list.sort_by{ |a| a.first }.reverse

      bigram_list.each do |(score, w1, w2)|
        output.puts "%s %s %s" % [score.to_s(' F'), w1, w2]
      end
    end

    # Output words and their ranks in groups according to the
    # first letter of the word.
    def letter_ranks(opts={})
      out = opts[:out] || $stdout
      max = opts[:max] || 12

      # sort by score
      word_scores = scoresheet.sort_by{ |w, s| s }.reverse

      letters = Hash.new{ |h,k| h[k] = [] }
      word_scores.each do |word, score|
        letters[word[0,1]] << [word, score]
      end

      letters.each do |letter, scores|
        out.puts(letter.upcase)
        scores.take(max).each do |(word, score)|
          out.puts("%s %s" % [score, word])
        end
        out.puts
      end
    end

    # Get a combined table of rank, word and bigrams.
    #
    # Returns [Array]
    def table(opts={})
      max_words = options[:max] || self.max_words

      word_scores = scoresheet(max_words)

      case opts[:sort].to_s
      when 'rank'
        word_scores = word_scores.sort_by{ |_,s| s }.reverse
      else
        word_scores = word_scores.sort_by{ |w,_| w.to_s }
      end

      tbl = []

      word_scores.each do |w, s|
        tbl << [s, w]
      end

      return tbl
    end

    # Get a combined table of rank, word and bigrams.
    #
    # Returns [Array]
    def table_with_bigrams(opts={})
      max_words = options[:max] || self.max_words

      word_scores = scoresheet(max_words)

      case opts[:sort].to_s
      when 'rank'
        word_scores = word_scores.sort_by{ |_,s| s }.reverse
      else
        word_scores = word_scores.sort_by{ |w,_| w.to_s }
      end

      tbl = []

      word_scores.each_with_index do |(w, s), i|
        bigram_list = bigrams.matching_bigrams(w)
        bigram_list = bigram_list.sort_by{ |b| bigrams.score(b) }.reverse
        bigram_list = bigram_list.map{ |b| b.word2 }.uniq
        bigram_list = bigram_list[0, self.max_bigrams]

        #output.puts "%-6s. %s %s %s" % [i, s.to_s(' F'), w, bigram_list.join(' ')]
        tbl << [s, w, bigram_list]
      end

      return tbl
    end

    # Output table of words with sort index and ranking.
    #
    # Returns nothing.
    def output_table(options={})
      output    = options[:out] || $stdout
      max_words = options[:max] || self.max_words
      indexed   = options[:index]

      word_scores = scoresheet(max_words)
      word_scores = word_scores.sort_by{ |w,_| w.to_s }

      list = []
      word_scores.each_with_index do |(w, s), i|
         list << [i, s, w]
      end

      if options[:sort].to_s == "rank"
        list = list.sort_by{ |_,s,_| s }.reverse
      end

      if options[:index]
        list.each do |i, s, w|
          #output.puts "%-6d %s %s" % [i, s.to_s(' F'), w]
          output.puts "%-6d %s %s" % [i, s, w]
        end
      else
        list.each do |i, s, w|
          output.puts "%s %s" % [s, w]
        end
      end
    end

    # Output combined table of words and bigrams.
    #
    # Returns nothing.
    def output_table_with_bigrams(options={})
      output    = options[:out] || $stdout
      max_words = options[:max] || self.max_words

      word_scores = scoresheet(max_words)

      case options[:sort].to_s
      when 'rank'
        word_scores = word_scores.sort_by{ |_,s| s }.reverse
      else
        word_scores = word_scores.sort_by{ |w,_| w.to_s }
      end

      word_scores.each_with_index do |(w, s), i|
        bigram_list = bigrams.matching_bigrams(w)
        bigram_list = bigram_list.sort_by{ |b| bigrams.score(b) }.reverse
        bigram_list = bigram_list.map{ |b| b.word2 }.uniq
        bigram_list = bigram_list[0, self.max_bigrams]

        #output.puts "%-6s. %s %s %s" % [i, s.to_s(' F'), w, bigram_list.join(' ')]
        output.puts "%s %s %s" % [s, w, bigram_list.join(' ')]
      end
    end

    #
    def ouput_ngrams
       max_ngrams = options[:max] || 1000
       ngrams.each do |score, *parts|
          output.print score
          parts.each do |part|
            output.print part
          end
          output.puts
       end
    end

    # Output the spelling hierarchy.
    def output_hierarchy(output=$stdout)
      hierarchy.print_tree(output)
    end

    ## Adjusted score.
    ##
    ## TODO: Should final score be an integer? Android's dictionary only uses 8-bit ints!
    ##        That's obviously too small, but we could do 16-bit ints and that would be
    ##        enough w/ 65,536 differnt scores.
    ##
    #def log(word)
    #  log = Math.log10(words.weighted_probabilty(word))
    #  inv = -(1 / log)
    #  (inv * 1000000000).to_i
    #end

=begin
  # Merge word list with bigram list to create an ordered
  # table of all words and their common bigrams.
  def save_table
    bigrams = {}

    bigrams_table.table.each do |w1, w2b|
      bigrams[w1] = w2b.sort_by{ |w2, b| b.probablity }.map{ |x| x[0] }.reverse
    end

    words = self.words.sort_by{ |w, r| r }.map{ |x| x[0] }.reverse
    words.uniq!

    sets = words.map do |word|
      [word] + (bigrams[word.downcase] || [])[0,6] # max 6 bigrams
    end

    File.open('table.txt', 'w') do |f|
      sets.each{ |w| f.puts(w.join(' ')) }
    end    
  end
=end

    #
    def output_letters(options={})
      size = options[:size] || 1
      norm = options[:norm]

      if norm
        letters.ngrams(size).each do |gram, freq|
          puts "%-6d %s" % [score(freq), gram]
        end
      else
        letters.ngrams(size).each do |gram, freq|
          puts "%2.12f %s" % [freq, gram]
        end
      end
    end

    # Create SQLite database of words.
    #
    # This creates a results database.
    #
    def create_database(opts={})
      max_words = opts[:max] || self.max_words

      word_list = datapoints(max_words || self.max_words)
      word_list = word_list.sort_by{ |_,b| b }.reverse
      #word_list = word_list.sort_by{ |w,_| w.to_s }

      bigram_list = []
      words.each_with_index do |(w, b), i|
        list = bigrams.matching_bigrams(w)
        list = list.sort_by{ |b| bigrams.score(b) }.reverse
        list = list[0, self.max_bigrams]
        list = list.map{ |b| [b.word1, b.word2, bigrams.probability(b) ] }
        bigram_list.concat(list)
      end

      db = DB.new
      db.save!(word_list, bigram_list)
    end

    # Load dictionary database.
    #
    # NOTE: Amazingly Ruby makes Java on Android look like a slow-poke.
    #
    def load_database
      db = DB.new
      start_time = Time.now
      words, bigrams = db.load!
      end_time = Time.now
      puts "Finished loading %d words in %f seconds." % [words.size, end_time - start_time]
    end

=begin
    #
    def word_list(max=nil)
      # get list of words in corpus
      list = words()
      # lookup the necessary words from the corpus
      necc_words = necessary_words(list)
      # sort words by score
      list = list.sort_by{ |w| words.score(w) }.reverse
      # take the max number of words
      list = list.take(max) if max
      # ensure the neccessary words are present
      list = list + necc_words
      # remove any duplicates (b/c of adding neccessary words)
      list.uniq!
      # return alphabetically sorted list
      #list.sort_by{ |w| w.spelling }
      list.sort_by{ |w| words.score(w) }.reverse
    end
=end

    # Return a list of words and their weighted probabilities.
    #
    # Returns [Hash]
    def datapoints(max=nil)
      a = []
      # go over each word and get score
      words.each do |w|
        a << [w.to_s, words.weighted_probability(w)]
      end
      # get necessary words and their scores
      n = necessary_scores(a)
      # take maximum number of words wanted
      if max
        a = a.sort_by{ |_, s| s }.reverse
        a = a.take(max.to_i)
      end
      # add necessary words
      a = a | n
      # sort by word
      a.sort_by{ |w, _| w }
    end

    # Return a list of words and their scores.
    #
    # Returns [Hash]
    def scoresheet(max=nil)
      a = []
      # go over each word and get score
      words.each do |w|
        a << [w.to_s, words.score(w)]
      end

      # get necessary words and their scores
      n = necessary_scores(a)
      # take maximum number of words wanted
      if max
        a = a.sort_by{ |_, s| s }.reverse
        a = a.take(max.to_i)
      end
      # remove n's trailing words to ensure size, but have to deal with dups too
      #a = a.take(a.size - n.size)
      # add necessary words
      a = a | n
      # sort by word
      a.sort_by{ |w, _| w }
    end

	  # Returns associative array of word/score pairs.
	  def necessary_scores(scores)
	    necc = []
	    necessary_words.each do |n|
	      score = scores.find{ |w, _| w == n.downcase }
	      necc << score if score
	    end
	    necc
	  end

    #
    def necessary_words
      @necessary_words ||= load_necessary_words
    end

    #
    def load_necessary_words
      list = []
      if necessary_file
        File.readlines(necessary_file).each do |line|
          line.strip!
          list << line unless line == ""
        end
      end
      list
    end

  private

    # The score is the calcualated by taking the inverse log and multipying
    # it by 65536. The higher the number, the more likely it is to occur.
    # 
    # Returns [Integer]
    def score(probability, max=65535)
      log10 = Math.log10(probability / 10)
      ((-1 / log10) * max).to_i
    end

  end

end
