# git_trello_post_commit

This gem can be used in a post-commit hook in any Git repository to comment on and move Trello cards in a specified board. The actions performed by the hook depend on the Git commit message. For example, if a message contains 'Card #20', the hook will add the rest of the commit message as a comment on card #20.

## Installation

Add this line to your application's Gemfile:

    gem 'git_trello_post_commit'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install git_trello_post_commit

## Setup

Add a file like this to your repo:

**my_repo/.git/hooks/post-commit**

    #!/usr/bin/env ruby
    require 'git_trello_post_commit'
    GitTrelloPostCommit::Hook.new(
      :api_key              => 'API_KEY',
      :oauth_token          => 'OAUTH_TOKEN',
      :list_id_in_progress  => 'LIST_ID_IN_PROGRESS',
      :list_id_done         => 'LIST_ID_IN_DONE',
      :board_id             => 'TRELLO_BOARD_ID',
      :commit_url_prefix    => 'https://github.com/my_github_username/my_repo/commits/' 
    ).run


Filling in the details using the following approach...

### api_key

Get your developer key from: https://trello.com/1/appKey/generate

### oauth_token

You need to authorize the app with `API_KEY` to access each board separatelly. To do that:

https://trello.com/1/authorize?response_type=token&name=`BOARD_NAME_AS_SHOWN_IN_URL`&scope=read,write&expiration=never&key=`API_KEY`

### list_id_in_progress & list_id_done

Open a card from your "in progress" and "completed" lists (or whatever you've called them), click the 'More' link in the bottom-right-hand corner, select 'Export JSON' and find the `idList` value.

### board_id

While examining the JSON from the previous step, you can also grab the value of `idBoard`.

### commit_url_prefix

If you have a web view of your Git repo (such as Github), you can enter the URL which, when sufixed with the commit SHA will show the commit in question. The hook will add a link to the commit in the comment it adds to the card.

If you ommit the parameter, a link won't be added.

## Usage

The gem uses the following regex to detect a reference to a card:

    /((case|card|close|fix)e?s? \D?([0-9]+))/i

So an example commit message might be:

    Added that awesome feature closes #42

For the 'case' and 'card' keywords, the card is moved to the list with id `LIST_ID_IN_PROGRESS`, while for keywords 'close' and 'fix', the card is moved to the list with id `LIST_ID_IN_DONE` .

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Acknowledgments

This gem is a quick-and-dirty mod of https://github.com/zmilojko/git-trello, so credit to [@zmilojko](https://github.com/zmilojko).