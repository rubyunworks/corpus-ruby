module Corpus

  ##
  # Database for results.
  #
  class DB

    DB_FILE = 'dictionary.db'

    def initialize(dir=Dir.pwd)
      require 'sqlite3'
      @db_file = File.join(dir, DB_FILE)
    end

    # Save words and bigrams to database.
    #
    def save!(words, bigrams)
      begin
        @db = SQLite3::Database.open(@db_file)
        save_words(words)
        save_bigrams(bigrams)
      ensure
        @db.close
      end
    end

    # Load words and bigrams from database.
    #
    def load!
      begin
        @db = SQLite3::Database.open(@db_file)
        words   = load_words
        bigrams = load_bigrams
      ensure
        @db.close
      end

      return words, bigrams
    end

    # Create table.
    #
    def create_table(name)
      case name
      when 'words'
        @db.execute %[CREATE TABLE "android_metadata" ("locale" TEXT DEFAULT 'en_US');]
        @db.execute %[INSERT INTO "android_metadata" VALUES ('en_US');]

        @db.execute "CREATE TABLE IF NOT EXISTS words(" \
                    "  _id INTEGER PRIMARY KEY, " \
                    "  spelling TEXT, " \
                    "  probability REAL " \
                    ");"
      when 'bigrams'
        @db.execute "CREATE TABLE IF NOT EXISTS bigrams(" \
                    "  _id INTEGER PRIMARY KEY, " \
                    "  word1 TEXT, " \
                    "  word2 TEXT, " \
                    "  probability REAL " \
                    ");"
      end
    end

    #
    def drop_table(name)
      @db.execute "DROP TABLE IF EXISTS #{name}"
    end

    # Save words to database.
    #
    def save_words(words)
      drop_table('words')
      create_table('words')

      index = 0
      size  = words.size

      $stdout.print "Storing Words: #{index}/#{size}"

      @db.prepare("INSERT INTO words (spelling, probability) VALUES (?, ?)") do |stmt|
        words.each do |spelling, probability|
          index += 1; $stdout.print "\r\e[KStoring Words] #{index}/#{size}"
          stmt.execute spelling, probability.to_f
        end
      end

      $stdout.puts
    end

    # Save bigrams to database.
    #
    def save_bigrams(bigrams)
      drop_table('bigrams')
      create_table('bigrams')

      index = 0
      size  = bigrams.size

      $stdout.print "[Storing Bigrams] #{index}/#{size}"

      @db.prepare("INSERT INTO bigrams (word1, word2, probability) VALUES (?, ?, ?)") do |stmt|
        bigrams.each do |word1, word2, probability|
          index += 1; $stdout.print "\r\e[K[Storing Bigrams] #{index}/#{size}"
          stmt.execute word1, word2, probability.to_f
        end
      end

      $stdout.puts
    end

    # Load words from database.
    #
    # Returns [Array<Word>]
    def load_words
      words = []

      begin
        sql = "SELECT spelling, probability FROM words;"
        stm = @db.prepare sql
        rs  = stm.execute
		    while (row = rs.next) do
		      s, b = *row
		      words << [s, b]
		    end
      ensure
        stm.close
      end

      words
    end

    # Load bigrams from database.
    #
    # Returns [Array<Bigram>]
    def load_bigrams
      bigrams = []

      begin
        sql = "SELECT word1, word2, probability FROM bigrams;"
        stm = @db.prepare sql
        rs  = stm.execute
		    while (row = rs.next) do
		      w1, w2, b = *row
		      bigrams << [w1, w2, b]
		    end
      ensure
        stm.close
      end

      bigrams
    end

  end

end
