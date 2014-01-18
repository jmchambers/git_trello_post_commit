require "git_trello_post_commit/version"
require "git_trello_post_commit/trello-http"

module GitTrelloPostCommit

  class Hook

    def initialize(config)
      @api_key = config[:api_key]
      @oauth_token = config[:oauth_token]
      @repodir = Dir.pwd
      @board_id = config[:board_id]
      @list_id_in_progress = config[:list_id_in_progress]
      @list_id_done = config[:list_id_done]
      @commit_url_prefix = config[:commit_url_prefix]

      @http = GitTrelloPostCommit::Trello::HTTP.new(@oauth_token, @api_key)
      @repo = Git.open(@repodir)
    end

    def test
      puts 'git-trello post-commit hook trigered just fine' 
    end

    def run

      #get the commit and it's sha from HEAD
      commit  = @repo.gcommit('HEAD')
      new_sha = commit.sha

      # Figure out the card short id
      match = commit.message.match(/((case|card|close|fix)e?s? \D?([0-9]+))/i)
      return unless match and match[3].to_i > 0

      puts "Trello: Commenting on the card ##{match[3].to_i}"

      results = @http.get_card(@board_id, match[3].to_i)
      unless results
        puts "Trello: Cannot find card matching ID #{match[3]}"
        return
      end
      results = JSON.parse(results)

      # Determine the action to take
      target_list_id = ""
      target_list_id = case match[2].downcase
        when "case", "card" then @list_id_in_progress
        when "close", "fix" then @list_id_done
      end
    
      # Add the commit comment
      message = "#{commit.author.name}:\n#{commit.message}"
      message << "\n\n#{@commit_url_prefix}#{new_sha}" unless @commit_url_prefix.nil?
      message.gsub!(match[1], "")
      message.gsub!(/\(\)$/, "")
      message.gsub!(/Signed-off-by: (.*) <(.*)>/,"")
      @http.add_comment(results["id"], message)

      unless target_list_id == ""
        to_update = {}
        unless results["idList"] == target_list_id
          puts "Trello: Moving card ##{match[3].to_i} to list #{target_list_id}"
          to_update[:idList] = target_list_id
          @http.update_card(results["id"], to_update)
        end
      end
          
    end

  end
end
