module Corpus

  class Lexicon
    include Enumerable
    include Utils

    #
    def self.instance(directory)
      @instance ||= {}
      @instance[directory] ||= new(directory) 
    end

    #
    def initialize(directory)
      dir = File.join(directory, 'lexicon')
      if File.directory?(dir)
        @directory = dir
      else
        @directory = directory
      end
      scan
    end

    #
    attr :directory

    #
    def each(&block)
      @set.each(&block)
    end

    #
    def size
      @set.size
    end

    #
    def member?(spelling)
      @set.member?(spelling)
    end
    alias :include? :member?

    # Scan dictionary files for all words.
    def scan
      $stderr.print "[lexicon] "

      dict = Set.new

      files.each do |file|
        if $DEBUG
          $stderr.puts "[scanning dictionary] #{file}" if $DEBUG
        else
          $stderr.print "."
        end

        text = File.read(file).gsub("\n", " ")
        states = text.split(/[.,:;?!()"]\s*/)

        states.each do |state|
          state.scan(WORD) do |word|
            word = normalize(word)
            dict << word if valid_word?(word)
          end
        end
      end

      @set = dict

      $stderr.puts
    end

    # Dictionary files.
    def files
      @files ||= Dir[File.join(directory, '**', '*.txt')]
    end

  end

end
