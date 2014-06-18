module Corpus

  ##
  # Model of a word and its stats.
  #
  class Word

    # The spelling of the word (basically the word itself).
    attr :spelling

    # How many times the bigram appears in total.
    attr :count

    # How many files does the bigram appear within.
    attr :files

    # Initialize new instance of Bigram.
    #
    # spelling   - The word itself.
    #
    def initialize(spelling)
      @spelling   = spelling
      @count      = 0
      @files      = Hash.new(0)
    end

    #
    def file!(file)
      @count += 1
      @files[file] += 1
    end

    # FIXME: This is far from perfect, but suffices for now.
    def plural?
      spelling.end_with?("s")
    end

    #
    def to_s
      spelling
    end

    #
    def ==(other)
      spelling == other.spelling
    end

    # TODO: Should we take file count into consideration?
    def <=>(other)
      count <=> other.count
    end

  end

end

