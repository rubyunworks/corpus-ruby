$LOAD_PATH.unshift(File.expand_path('lib'))

require 'corpus'

desc "generate full word table with rankings"
task :table do
  corpus = Corpus::Main.new(corpus_directory)
  corpus.output_table(:out=>$stdout, :max=>ENV['max'], :sort=>ENV['sort'])
end

desc "generate word rankings list"
task :words do
  corpus = Corpus::Main.new(corpus_directory)
  corpus.output_words
end

desc "list words and ranks by first letter"
task :alpharank do
  corpus = Corpus::Main.new(corpus_directory)
  corpus.letter_ranks
end

desc "display letter frequencies"
task :letters do
  corpus = Corpus::Main.new(corpus_directory)
  size   = (ENV['size'] || 1).to_i
  norm   = ENV['norm']
  corpus.output_letters(:size=>size, :norm=>norm)
end

desc "generate spelling hierarchy"
task :hierarchy do
  corpus = Corpus::Main.new(corpus_directory)
  corpus.output_hierarchy(:out=>$stdout)
end

namespace :db do
  desc "generate analysis cache database (will speed up later runs)"
  task :cache do
    corpus = Corpus::Main.new(corpus_directory)
    #corpus.create_database(ENV['max'])
  end

  desc "generate results database for words and bigrams"
  task :save do
    corpus = Corpus::Main.new(corpus_directory)
    corpus.create_database(:max=>ENV['max'])
  end

  desc "load words and bigrams from results database"
  task :load do
    corpus = Corpus::Main.new(corpus_directory)
    corpus.load_database()
  end
end

=begin
# Layout evolution tasks
namespace :evo do

	desc "Score my boards"
	task :score do
		corpus = Corpus::Main.new(corpus_directory)

		Corpus::Layout::LAYOUTS.each_with_index do |(name, layout), i|
		  layout = Corpus::Layout.new(layout, corpus)
		  puts("%2d) %-30s %10d" % [i+1, name, layout.score])
		end

		name   = "Random Layout"
		layout = Corpus::Layout.random(corpus)
		puts("%2d) %-30s %10d" % [0, name, layout.score])
	end

	desc "Search for best layout."
	task :search do
		corpus = Corpus::Main.new(corpus_directory)
		corpus.search
	end

	desc "Evolve best layout."
	task :evolve do
		corpus = Corpus::Main.new(corpus_directory)
		corpus.evolve
	end

	#desc "Simple letter maximum board"
	#task :max do
	#  corpus = Corpus::Main.new(corpus_directory)
	#
	#  layout = Corpus::Layout.maximum
	#  puts layout
	#  puts "Score: %s" % [layout.score(corpus)]
	#end
end
=end

def corpus_directory
  if ENV['sample']
    'work/samples'
  else
    'data/corpus'
  end
end

