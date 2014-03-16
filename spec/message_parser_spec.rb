require 'rspec'
require 'pry'
require 'git_trello_post_commit'

module GitTrelloPostCommit

  describe MessageParser do 
    it "parses single instructions at the end of the message" do
      parser = MessageParser.new("fixed that thing, closes #99")
      expect(parser.instructions).to eq({99 => :done})
    end

    it "parses single instructions in the middle of a message" do
      parser = MessageParser.new("fixed that thing, closes #99, blah, blah, blah")
      expect(parser.instructions).to eq({99 => :done})
    end

    it "parses multiple distinct references" do
      parser = MessageParser.new("fixed that thing, closes #99, refs #100")
      expect(parser.instructions).to eq({99 => :done, 100 => :in_progress})
    end

    it "parses a space separated list of ids for a single action keyword" do
      parser = MessageParser.new("fixed that thing, closes #99 #100 #101")
      expect(parser.instructions).to eq({99 => :done, 100 => :done, 101 => :done})
    end

    it "parses a csv list of ids for a single action keyword" do
      parser = MessageParser.new("fixed that thing, closes #99, #100, #101")
      expect(parser.instructions).to eq({99 => :done, 100 => :done, 101 => :done})
    end

    it "parses a csv list of ids (ending with an 'and') for a single action keyword" do
      parser = MessageParser.new("fixed that thing, closes #99, #100 and #101")
      expect(parser.instructions).to eq({99 => :done, 100 => :done, 101 => :done})
    end

    it "parses a csv list of ids (ending with an '&') for a single action keyword" do
      parser = MessageParser.new("fixed that thing, closes #99, #100 & #101")
      expect(parser.instructions).to eq({99 => :done, 100 => :done, 101 => :done})
    end

    it "parses a csv list of ids (ending with an ', and') for a single action keyword" do
      parser = MessageParser.new("fixed that thing, closes #99, #100, and #101")
      expect(parser.instructions).to eq({99 => :done, 100 => :done, 101 => :done})
    end

    it "parses multiple lists of ids for a single action keyword" do
      parser = MessageParser.new("fixed that thing, closes #99, #100 & #101 and refs #1 & #2")
      expect(parser.instructions).to eq({
        99 => :done, 100 => :done, 101 => :done,
        1  => :in_progress, 2 => :in_progress
      })
    end

    it "ignores duplicate instructions" do
      parser = MessageParser.new("fixed that thing on card #99, refs #99")
      expect(parser.instructions).to eq({99 => :in_progress})
    end

    it "ignores duplicate instructions give in a list" do
      parser = MessageParser.new("fixed the things on cards #99 and #100, refs #99, #100")
      expect(parser.instructions).to eq({99 => :in_progress, 100 => :in_progress})
    end

    it "ignores conflicting instructions, favouring :done over :in_progress" do
      parser = MessageParser.new("fixed that thing on card #99, closes #99")
      expect(parser.instructions).to eq({99 => :done})
    end
  end

end