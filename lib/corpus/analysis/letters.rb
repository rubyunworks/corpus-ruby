module Corpus

  module Analysis

    ##
    # Letter analysis.
    #
    class Letters
      #include Enumerable

      # Initialize Letters analysis instance.
      #
      # directory -
      #
      def initialize(directory)
        @lexicon = Lexicon.instance(directory)
        @n_grams = Hash.new{ |h,k| h[k.to_i] = Hash.new(0.0) }
      end

      #
      def ngrams(n=nil)
        if n
          @n_grams[n.to_i]
        else
          @n_grams
        end
      end

      #
      def empty?
        @n_grams.empty?
      end

      #
      def [](size)
        @n_grams[size.to_i]
      end

      #
      def []=(letters,count)
        @n_grams[letters.size][letters] = count
      end

      # Defaults to unigrams.
      #def each(n=1,&b)
      #  @n_grams[n].each(&b)
      #end

      # Scan corpus for letter patterns.
      #
      # TODO: Add apostrophe to letter regexp?
      #
      def scan
        $stderr.print "[letters] "

        grams = Hash.new{ |h,k| h[k.to_i] = Hash.new(0.0) }

        #last = nil
        #total = 0

        files.each do |file|
          #$stderr.puts "[scanning] #{file}"
          $stderr.print "."

          text = File.read(file).gsub("\n", " ")

          sequence = ""

          text.each_char do |letter|
            letter = letter.downcase
            if /[a-zA-Z]/ =~ letter
              sequence << letter
              sequence.size.times do |s|
                tail = sequence[s..-1] #.last(s+1)
                grams[tail.size][tail] += 1
              end
              #pairs[last + letter] += 1 if last
              #sings[letter] += 1
              #last = letter
            else
              sequence = ""
            end
          end
        end

        totals = Hash.new{ |h,k| h[k] = Hash.new(0.0) }

        grams.each do |size, entries|
          totals[size] = entries.values.inject(0) { |t, c| t += c }
        end

        grams.each do |size, entries|
          entries.each do |gram, count|
            @n_grams[size][gram] = (count / totals[size])
          end
        end

        $stderr.puts
      end

    private

      #
      def files
        @files ||= Dir[File.join(directory, 'corpus', '**', '*.txt')]
      end

    end

  end

end
