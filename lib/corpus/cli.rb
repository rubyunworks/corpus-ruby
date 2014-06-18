require 'clik'

module Corpus

  class CLI

    #
    def self.execute!(argv=ARGV)
      new.send(*argv)
    end

    # Output the combined table of words and bigrams.
    def index(*argv)
      CLI::Index.run(argv)
    end

    # Output the word analysis.
    def words(*argv)
      CLI::Words.run(argv)
    end

    # Output n-gram analysis.
    def ngrams(*argv)
      CLI::NGrams.run(argv)
    end

    # Output letter analysis.
    def letters(*argv)
      CLI::Letters.run(argv)
    end

    #
    def hierarchy(*argv)
      CLI::Hierarchy.run(argv)
    end

    #
    #def merge(*files)
    #  Merge.run(*files)
    #end
  end

end

