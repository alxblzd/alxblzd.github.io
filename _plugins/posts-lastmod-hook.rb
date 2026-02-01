#!/usr/bin/env ruby
#
# Check for changed posts

Jekyll::Hooks.register :posts, :post_init do |post|

  git_available = system("git --version > /dev/null 2>&1")
  git_repo = git_available && system("git rev-parse --is-inside-work-tree > /dev/null 2>&1")
  next unless git_repo

  commit_num = `git rev-list --count HEAD "#{ post.path }"`
  next unless commit_num.to_i > 1

  lastmod_date = `git log -1 --pretty="%ad" --date=iso "#{ post.path }"`
  post.data['last_modified_at'] = lastmod_date

end
