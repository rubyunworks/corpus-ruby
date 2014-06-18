module Corpus

  ##
  # Utils module contains comman constants and functions that any
  # of the other various classes might have in common.
  #
  module Utils

    WORD = /\b[a-zA-Z][a-zA-Z']*/

    ACCEPT_WORDS = %w{
      a i ab ad ah am an as at be bi by co do ed em en ex fe fx go
      he ho it is id if in jr me mr my mc no or of oh ok on ox pi pc
      re si so to up us un we
    }

    REJECT_WORDS = %w{n't d'n lea}

    # Normalize a word.
    def normalize(word)
      word = word.downcase
      word = word.sub(/^-+/, '') if word.start_with?('-')
      word
    end

    # Ensure a given word is valid.
    def valid_word?(word)
      return true  if ACCEPT_WORDS.include?(word)
      return false if REJECT_WORDS.include?(word)
      return false if word.size < 3
      return false if word.size > 20
      return false if word.start_with?("'")
      return false if word.end_with?("'")
      true
    end

  end

end
