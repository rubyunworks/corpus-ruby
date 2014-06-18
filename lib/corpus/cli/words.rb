module Corpus

  class CLI

    # NGrams command analyzes the corpus for consecutive combinations of words.
    # Typically these are pairs called bigrams. Triplets, called trigrams, are
    # of particular interest, but beyond that there tends to be few significant
    # patterns. Nonetheless this command can handle and size n-gram.
    #
    # Command line options are:
    #
    #      -m --max    Maximum top ranked words to output.
    #      -r --rank   Type of ranking (probablility, count, none).
    #      -c --ceil   Normalize scores to ceiling.
    #      -s --sort   Sort alphabetically instead of by rank.
    #      -d --debug  Run in debug mode.
    #      -h --help   Show help message.
    #
    class Words
      include Utils

      #
      def self.run(argv=ARGV)
        new(argv).run
      end

      # Initialize and parse command line arguments.
      def initialize(argv)
        @max  = 65535
        @ceil = nil
        @rank_type = 'count'
        @sort = false

        args = cli argv,
          '-m --max'   => lambda{ |m| @max = m.to_i },
          '-r --rank'  => lambda{ |r| @rank_type = r },
          '-s --sort'  => lambda{ @sort = true },
          '-c --ceil'  => lambda{ |c| @ceil = c.to_i },
          '-d --debug' => lambda{ $DEBUG = true },
          '-h --help'  => lambda{ show_help }

        directory = args.first

        raise "Directory does not exist -- #{directory}" unless File.directory?(directory)

        @words = Analysis::Words.new(directory)
      end

      # Instance of [Analysis::Words]. 
      attr :words

      # Maximum number of n-grams to show. [Integer]
      attr :max

      # Type of ranking score to display. [String]
      attr :rank_type

      # Ceiling value of ranks. Values will be normalize to not exceed this value. [Integer]
      attr :ceil

      # Sort alphabetically. [Boolean]
      attr :sort

      # Run the command.
      def run
        words.scan

        list = words.top_weighted(max)

        if sort
          list = list.sort_by{ |w| w.to_s }
        end

        case rank_type.downcase
        when 'c', 'a', 'count', 'abs', 'absolute'
          if ceil
            list.each do |word|
              puts("%d %s" % [norm(word.count), word])
            end
          else
            list.each do |word|
              puts("%d %s" % [word.count, word])
            end
          end
        when 'p', 'pro', 'prob', 'probability'
          if ceil
            list.each do |word|
              #probability = words.probability(word)
              probability = words.weighted_probability(word)
              puts("%d %s" % [ilog(probability), word])
            end        
          else
            list.each do |word|
              #probability = words.probability(word)
              probability = words.weighted_probability(word)
              puts("%.12f %s" % [probability, word])
            end
          end
        when 'l', 'log', 'ilog'
          list.each do |word|
            #probability = words.probability(word)
            probability = words.weighted_probability(word)
            puts("%d %s" % [ilog(probability), word])
          end
        when 'n', 'no', 'none'
          list.each do |word|
            puts word
          end
        else
          raise "Unknown rank type -- #{rank_type}"
        end
      end

      # This method calcualates the inverse log of the probability,
      # divided by ten, and multipying it by `ceil`. Thus higher the number,
      # the more likely it is to occur. This is used to normalize the set
      # of probablities to a limited integer range.
      #
      # Rank requires a ceiling, so it defaults to 65535 if none is given.
      #
      # Returns [Integer]
      def ilog(probability)
        max = ceil || 65535
        log10 = Math.log10(probability / 10)
        ((-1 / log10) * max).to_i
      end

      # Nomalize count to be within the range of zero and the given ceiling.
      #
      # Returns [Integer]
      def norm(count)
        (count * ceil) / words.max_count
      end

    end

  end

end
