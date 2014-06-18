module Corpus

  class CLI

    # NGrams command analyzes the corpus for consecutive combinations of words.
    # Typically these are pairs called bigrams. Triplets, called trigrams, are
    # of particular interest, but beyond that there tends to be few significant
    # patterns. Nonetheless this command can handle and size n-gram.
    #
    # Command line options are:
    #
    #      -n --num    The "n" in n-gram. Can be a range.
    #      -m --max    Maximum top ranked n-grams to output.
    #      -r --rank   Ranking type (count, probability, none).
    #      -c --ceil   Normalize rank scores to ceiling.
    #      -s --sort   Sort alphabetically instead of by rank.
    #      -d --debug  Run in debug mode.
    #      -h --help   Show help message.
    #
    class NGrams

      #
      def self.run(argv=ARGV)
        new(argv).run
      end

      # Initialize and parse command line arguments.
      def initialize(argv)
        @max  = 10000
        @ceil = nil
        @rank_type = 'p'
        @sort = false

        args = cli argv,
          '-n --num'   => lambda{ |d| self.number = d },
          '-m --max'   => lambda{ |m| @max = m.to_i },
          '-r --rank'  => lambda{ |r| @rank_type = r },
          '-c --ceil'  => lambda{ |c| @ceil = c.to_i },
          '-s --sort'  => lambda{ @sort = true },
          '-d --debug' => lambda{ $DEBUG = true },
          '-h --help'  => lambda{ show_help }

        directory = args.first

        raise "Directory does not exist -- #{directory}" unless File.directory?(directory)

        @ngrams = Analysis::NGrams.new(directory, :n=>@number)
      end

      # Instance of Analysis::NGrams
      attr :ngrams

      # n-gram size (2 for bigrams, 3 for trigrams, etc.)
      attr :number

      # Maximum number of n-grams to show.
      attr :max

      # type of ranking to output.
      attr :rank_type

      # Ceiling value of ranks. Values will be normalize to not exceed this value.
      attr :ceil

      # Sort alphabetically or not. [Boolean]
      attr :sort

      # Number can be an integer or a range of integer.
      #
      #     ngrams.number = 2
      #     ngrams.number = 2..3
      #
      # If a string is given instead, it will be parsed as such.
      #
      #     ngrams.number = "2"
      #     ngrams.number = "2..3"
      #
      # Returns [Integer,Range].
      def number=(n)
        case n
        when String
          case n
          when /(\d+)[,.;:]+(\d+)/
            @number = (($1.to_i)..($2.to_i))
          else
            @number = n.to_i
          end
        else
          @number = n
        end
      end

      # Run the n-grams command.
      def run
        ngrams.scan

        list = ngrams.sorted_by_rank(true).take(max)

        if sort
          list.sort_by!{ |(count, ngram)| ngram }
        end

        case rank_type.downcase
        when 'abs', 'count', 'a', 'c'
          if ceil
            list.each do |count, ngram|
              puts("%d %s" % [norm(count), ngram])
            end
          else
            list.each do |count, ngram|
              puts("%d %s" % [count, ngram])
            end
          end
        when 'p', 'pro', 'prob', 'probability'
          if ceil
            list.each do |count, ngram|
              probability = count.to_f / ngrams.total
              puts("%d %s" % [ilog(probability), ngram])
            end        
          else
            list.each do |count, ngram|
              probability = count.to_f / ngrams.total
              puts("%.12f %s" % [probability, ngram])
            end
          end
        when 'l', 'i', 'log', 'ilog'
          list.each do |count, ngram|
            probability = count.to_f / ngrams.total
            puts("%d %s" % [ilog(probability), ngram])
          end
        when 'no', 'none'
          list.each do |count, ngram|
            #probability = count.to_f / ngrams.total
            puts ngram
          end
        else
          raise "Unknown rank type -- #{rank_type}"
        end
      end

      # Rank is the calcualated by taking the inverse log of the probability
      # divided by ten and multipying it by `max`. Thus higher the number,
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
        (count * ceil) / ngrams.max_count
      end

      #
      def show_help
        puts "NGrams command analyzes the corpus for consecutive combinations of words."
        puts "Typically these are pairs called bigrams. Triplets, called trigrams, are"
        puts "of particular interest, but beyond that there tends to be few significant"
        puts "patterns. Nonetheless this command can handle and size n-gram."
        puts
        puts "Command line options are:"
        puts
        puts "     -n --num    The 'n' in n-gram. Can be a range."
        puts "     -m --max    Maximum top ranked n-grams to output."
        puts "     -r --rank   Ranking type (count, probability, none)."
        puts "     -c --ceil   Normalize rank scores to ceiling."
        puts "     -s --sort   Sort alphabetically instead of by rank."
        puts "     -d --debug  Run in debug mode."
        puts "     -h --help   Show help message."
        puts
        exit
      end

    end

  end

end
