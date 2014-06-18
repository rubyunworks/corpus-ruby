module Corpus

  class CLI

    class Letters

      #
      def self.run(argv=ARGV)
        new(argv).run
      end

      # Initialize and parse command line arguments.
      def initialize(argv)
        @max  = 10000
        @ceil = nil

        args = cli argv,
          '-n --num'   => lambda{ |d| @num = d.to_i },
          '-m --max'   => lambda{ |m| @max = m.to_i },
          '-a --abs'   => lambda{ @abs = true },
          '-c --ceil'  => lambda{ |c| @ceil = c.to_i },
          '-d --debug' => lambda{ $DEBUG = true },
          '-h --help'  => lambda{ show_help }

        directory = args.first

        @letters = Analysis::Letters.new(directory)
      end

      #
      def run
      end

    end

  end

end
