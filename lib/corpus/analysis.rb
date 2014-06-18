module Corpus

  ##
  # The Analysis module.
  #
  module Analysis

    #
    # Load analysis from a cache.
    #
    #def self.cache(corpus_directory)
    #  analysis = new(corpus_directory)
    #  analysis.load!
    #  analysis    
    #end


    # Directory containing `corpus/*.txt` files.
    attr :directory

    #
    attr :lexicon

    #
    alias :dictionary :lexicon

    #
    #def words
    #  @words.scan(files) if @words.empty?
    #  @words
    #end

    #
    #def bigrams
    #  @bigrams.scan(bigram_files) if @bigrams.empty?
    #  @bigrams
    #end

    #
    #def letters
    #  @letters.scan(files) if @letters.empty?
    #  @letters
    #end

    #
    # Get Word instance.
    #
    #def word(word)
    #  words.get(word)
    #end

    #
    # Get Bigram instance.
    #
    #def bigram(word1, word2)
    #  bigrams.get(word1, word2)
    #end

    ##
    ## Load scans.
    ##
    #def load!
    #  files.each do |file|
    #    $stderr.puts "Load: #{file}"
    #    scans[file] = Scanner.cache(file)
    #  end
    #end

    # List of corpus text files to be analyzed, must be in `corpus` subdirectory.
    def files
      @files ||= Dir[File.join(directory, 'corpus', '**', '*.txt')]
    end



    #
    # Sace file counting words and bigrams.
    #
    def scan_words
      @words.scan(files)
    end

    #
    # Sace file counting words and bigrams.
    #
    def scan_bigrams
      @bigrams.scan(bigrams_files)
    end

    # Iterate over each word.
    def each_word(&b)
      words.each_word(&b)
    end

    #
    def each_bigram(&b)
      bigrams.each_bigrams(&b)
    end

    #
    def has_word?(word)
      words.key?(word.to_s)
    end

    ##
    ## Total word count.
    ##
    #def total
    #  sum = 0
    #  words.each do |word, count|
    #    sum += count
    #  end
    #  sum
    #end

    #
    # Save scan to cache file.
    #
    #def save!
    #  cache_file = File.join(File.dirname(file), '.corpus', File.basename(file) + '.yml')
    #
    #  FileUtils.mkdir_p(File.dirname(cache_file))
    #
    #  File.open(cache_file, 'w') do |f|
    #    f << to_yaml
    #  end
    #end

    # TODO: The cache has proven useless. It takes as long to load then it does to scan the corpus.
    #        If we really want to cache the data we need to use SQLite database.

    # TODO: Add letters
    def save_cache(file)
      data = { 
        'bigrams'    => bigrams.to_cache,
        'words'      => words.to_cache,
        'dictionary' => dictionary
      }

      File.open(file, "w"){ |f| f << data.to_yaml }
    end

    #
    def load_cache(file)
      data = YAML.load_file(file)

      words.from_cache(data['words'])
      bigrams.from_cache(data['bigrams'])

      @dictionary = data['dictionary']
    end

    #
    def inspect
      "#<Analysis #{words.size} words>"
    end

  end

end

