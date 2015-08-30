require "git_trello_post_commit/version"
require "git_trello_post_commit/trello-http"
require "json"
require "git"

module GitTrelloPostCommit

  DONE_KEYWORDS        = [:close, :fix]
  IN_PROGRESS_KEYWORDS = [:ref, :case, :issue, :card]

  KEYWORD_REGEX = /((ref)(?:erence)?s?|(case)s?|(issue)s?|(card)s?|(close)s?|(fix)(?:es)?)/i
  ID_REGEX      = /\#(?:\d+)/
  ID_LIST_REGEX = /\s*((?:#{ID_REGEX}(?:[,;]?\s+(?:and|\&)|[,;])?\s*)+)/i
  REF_REGEX     = /#{KEYWORD_REGEX}\s+#{ID_LIST_REGEX}/

  ID_CAPTURE_REGEX = /\#(\d+)/

  class MessageParser

    def initialize(message)
      @message = message
    end

    def instructions
      @instructions ||= parse_instructions
    end

    def parse_instructions
      raw_matches = get_raw_matches
      matches = extract_instructions(raw_matches)
      normalize_matches(matches)
    end

    def get_raw_matches
      @message.scan(REF_REGEX).map do |match|
        match.compact[1..-1]
      end
    end

    def categorize_keyword(keyword)
      if DONE_KEYWORDS.include?(keyword) then :done
      elsif IN_PROGRESS_KEYWORDS.include?(keyword) then :in_progress 
      end
    end

    def extract_instructions(raw_matches)
      raw_matches.reduce(Hash.new { |hash, key| hash[key] = [] }) do |matches, raw_match|
        keyword = raw_match.first.downcase.to_sym
        id_list = raw_match.last
        if keyword and id_list
          ids = id_list.scan(ID_CAPTURE_REGEX).flatten.map(&:to_i).select { |n| n>0 }
          ids.each do |id|
            matches[id] << keyword
          end
        end
        matches
      end
    end

    def normalize_matches(matches)
      matches.reduce({}) do |norm_matches, (card_id, keywords)|
        keywords.uniq!
        categories = keywords.map { |kw| categorize_keyword(kw) }.compact.uniq
        if categories.length > 1 and categories.include?(:done)
          norm_matches[card_id] = :done
        elsif categories.length == 1
          norm_matches[card_id] = categories.first
        end
        norm_matches
      end
    end

  end

  class Hook

    def initialize(config)
      @api_key = config[:api_key]
      @oauth_token = config[:oauth_token]
      @repodir = config[:repodir] || Dir.pwd
      @board_id = config[:board_id]
      @list_id_in_progress = config[:list_id_in_progress]
      @list_id_done = config[:list_id_done]
      @commit_url_prefix = config[:commit_url_prefix]

      @http = GitTrelloPostCommit::Trello::HTTP.new(@oauth_token, @api_key)
      @repo = Git.open(@repodir)
    end

    def run

      #get the commit and it's sha from HEAD
      commit  = @repo.gcommit('HEAD')
      new_sha = commit.sha

      parser = MessageParser.new(commit.message)

      parser.instructions.each do |card_id, action|

        puts "Trello: Commenting on card ##{card_id}"

        results = @http.get_card(@board_id, card_id)
        unless results
          puts "Trello: Cannot find card matching ID #{card_id}"
          next
        end
        results = JSON.parse(results)

        # Determine the action to take
        target_list_id = case action
          when :in_progress then @list_id_in_progress
          when :done        then @list_id_done
        end
      
        # Add the commit comment
        message = "#{commit.author.name}:\n#{commit.message}"
        message << "\n\n#{@commit_url_prefix}#{new_sha}" unless @commit_url_prefix.nil?
        message.gsub!(/\(\)$/, "")
        message.gsub!(/Signed-off-by: (.*) <(.*)>/,"")
        @http.add_comment(results["id"], message)

        if target_list_id
          to_update = {}
          unless results["idList"] == target_list_id
            puts "Trello: Moving card ##{card_id} to list #{target_list_id}"
            to_update[:idList] = target_list_id
            to_update[:pos]    = "top"
            @http.update_card(results["id"], to_update)
          end
        end

      end
          
    end

  end
end
