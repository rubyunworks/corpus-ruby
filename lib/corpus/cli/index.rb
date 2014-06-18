module Corpus

  class CLI

    class Index

      ## 
      # Generate an index table including word, rank and top three bigram indexes.
      # This table is used by the Taphonic keyboard app to load in all the information
      # it needs to provide pretty good spell corection and word prediction.
      #
      #     -m --max    Maximum number of top words to include.
      #     -s --sort   Sort alphabetically, instead of by rank.
      #     -d --debug  Run in debug mode.
      #     -h --help
      #
      def self.run(argv=ARGV)
        new(argv).run
      end

      # Initialize and parse command line arguments.
      def initialize(argv)
        @max  = 65535
        @ceil = nil
        @num  = 3

        args = cli argv,
          '-n --num'   => lambda{ |d| @num = d.to_i },
          '-m --max'   => lambda{ |m| @max = m.to_i },
          '-s --sort'  => lambda{ @sort = true },
          '-a --abs'   => lambda{ @abs = true },
          '-c --ceil'  => lambda{ |c| @ceil = c.to_i },
          '-d --debug' => lambda{ $DEBUG = true },
          '-h --help'  => lambda{ show_help }

        @directory = args.first
      end

      # Number of bigrams per word to include.
      attr :num

      # Maximum number of words to output.
      attr :max

      # Sort alphabetically if true.
      attr :sort

      #
      #attr :abs

      #
      attr :ceil

      # The directory which holds the `corpus` and `lexicon` subdirectories.
      attr :directory

      # Instance of {Analysis::Words}.
      attr :words

      # Instance of {Analysis::Bigrams}.
      attr :bigrams

      #
      def run
        @words   = Analysis::Words.new(directory)
        @bigrams = Analysis::Bigrams.new(directory)

        table.each do |s, w, bl|
          #output.puts "%-6s. %s %s %s" % [i, s.to_s(' F'), w, bigram_list.join(' ')]
          puts "%d %s %s" % [s, w, bl.join(' ')]
        end
      end

      # Output a combined table of word, rank and bigrams by index+1.
      # The bigram index is incremented by one so that zero can be used
      # to mean "no bigram".
      #
      # Returns [Array]
      def table
        words.scan
        bigrams.scan

        list = words.top_weighted(max)

        if sort
          list = list.sort_by{ |w| w.to_s }
        end

        index = {}
        list.each_with_index do |w, i|
          index[w.spelling] = i
        end

        tbl = []

        list.each_with_index do |w, i|
          s = ilog(words.weighted_probability(w))

          blist = bigrams.matching_bigrams(w.to_s)
          blist = blist.sort_by{ |b| bigrams.score(b) }.reverse
          blist = blist.map{ |b| b.word2 }.uniq

          b = []
          blist.each do |w|
            i = index[w]
            b << i+1 if i
            break if b.size == num
          end

          # ensure there are at least the required number of bigrams
          until b.size >= num
            b << 0
          end

          tbl << [s, w, b]
        end

        return tbl
      end

      # This methtod takes the inverse log of the given probability,
      # divided by ten, and multipying it by `ceil`. Thus higher the number,
      # the more likely it is to occur. This is used to normalize the set
      # of probablities to a limited integer range.
      #
      # The inverse log requires a ceiling, so it defaults to 65535 if not given.
      #
      # Returns [Integer]
      def ilog(probability)
        max = ceil || 65535
        log10 = Math.log10(probability / 10)
        ((-1 / log10) * max).to_i
      end

=begin
      # Return a list of words and their scores.
      #
      # Returns [Hash]
      def scoresheet
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
        #a = a.sort_by{ |w, _| w }
        return a
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
=end

    end

  end

end
