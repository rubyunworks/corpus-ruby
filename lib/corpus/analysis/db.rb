module Corpus

  # Database backend to store analysis.
  #
  # TODO: Load and save letter analysis.
  #
  class DB

    DB_FILE = 'corpus.db'

    def initialize
      require 'sqlite3'
    end

    #
    def load!
      begin
        @db = SQLite3::Database.open(DB_FILE)
        words   = load_words
        bigrams = load_bigrams
      ensure
        @db.close
      end
      return words, bigrams
    end

    #
    def save!(words, bigrams)
      begin
        @db = SQLite3::Database.open(DB_FILE)
        create_tables
        save_words(words)
        save_bigrams(bigrams)
      ensure
        @db.close
      end
    end

    #
    def create_tables
      @db.execute "CREATE TABLE IF NOT EXISTS Words(" \
                 "  word_id INTEGER PRIMARY KEY, " \
                 "  spelling VARCHAR(20), " \
                 "  count INT " \
                 ")"

      @db.execute "CREATE TABLE IF NOT EXISTS WordFiles(" \
                 "  file_id INTEGER PRIMARY KEY, " \
                 "  word_id INTEGER, " \
                 "  file_path TEXT, " \
                 "  file_count INT " \
                 ")"

      @db.execute "CREATE TABLE IF NOT EXISTS Bigrams(" \
                 "  bigram_id INTEGER PRIMARY KEY, " \
                 "  word1 VARCHAR(20), " \
                 "  word2 VARCHAR(20), " \
                 "  count INT " \
                 ")"

      @db.execute "CREATE TABLE IF NOT EXISTS BigramFiles(" \
                 "  file_id INTEGER PRIMARY KEY, " \
                 "  bigram_id INTEGER, " \
                 "  file_path TEXT, " \
                 "  file_count INT " \
                 ")"
    end

    # Load words from database.
    #
    # Returns [Array<Word>]
    def load_words
      words = []

      begin
        sql = "SELECT word_id, spelling, count FROM Words;"
        stm = @db.prepare sql
        rs  = stm.execute
		    while (row = rs.next) do
		      id, s, c = *row
		      words << Word.new(s, :count=>c, :id=>id)
		    end
      ensure
        stm.close
      end

      begin 
        sql = "SELECT file_path, file_count FROM WordFiles WHERE word_id = ?"
        stm = @db.prepare sql

		    words.each do |w|
		      rs = stm.execute(w.id)
		      files = {}
		      while (row = rs.next) do
		        path, count = *row
		        files[path] = count
		      end
		      w.files = files
		    end
      ensure
        stm.close
      end

      return words
    end

    # Load bigrams from database.
    #
    # Returns [Array<Bigram>]
    def load_bigrams
      bigrams = []

      begin
        sql = "SELECT bigram_id, word1, word2, count FROM Bigrams;"
        stm = @db.prepare sql
        rs  = stm.execute
		    while (row = rs.next) do
		      id, w1, w2, c = *row
		      bigrams << Bigrams.new(w1, w2, :count=>c, :id=>id)
		    end
      ensure
        stm.close
      end

      begin 
        sql = "SELECT file_path, file_count FROM BigramFiles WHERE bigram_id = ?"
        stm = @db.prepare sql

		    bigrams.each do |b|
		      rs = stm.execute(b.id)
		      files = {}
		      while (row = rs.next) do
		        path, count = *row
		        files[path] = count
		      end
		      b.files = files
		    end
      ensure
        stm.close
      end

      return bigrams
    end

    #
    def save_words(words)

    end

    #
    def save_bigrams(bigrams)

    end

  end

end
