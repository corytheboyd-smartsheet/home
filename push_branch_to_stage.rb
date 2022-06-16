#!/usr/bin/env ruby

require 'logger'
require 'json'

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'git'
end

class State
  def initialize
    @file = File.expand_path("~/.push_branch_to_stage.state.json")
    @data = {}
  end

  def hydrate!
    return unless File.exists?(file)

    @data = JSON.parse(File.read(file))
  end

  def persist!
    File.write(file, JSON.generate(data))
  end

  def get(key)
    data[key]
  end

  def set(key, value)
    data[key] = value
  end

  def delete(key)
    data.delete(key)
  end

  private

  attr_reader :file, :data
end

class Runner
  def initialize(state, git, logger)
    @state = state
    @git = git
    @logger = logger
  end

  def run!
    feature_branch = git.current_branch

    if %w(master main stage).include?(feature_branch)
      logger.error("On protected branch: #{feature_branch}")
      exit 1
    end

    stage_branch = git.branch('stage')
    stage_branch.checkout

    logger.info('Resetting local stage branch to origin')
    git.reset_hard('origin/stage')
    git.pull('origin', 'stage')

    previous_commit_sha = state.get(feature_branch)
    if previous_commit_sha
      logger.info("Previous commit sha found: #{previous_commit_sha}")

      if stage_branch.contains?(previous_commit_sha)
        logger.info('Reverting previous commit')
         git.revert(previous_commit_sha)
      else
        logger.warn('Previous commit sha removed from stage branch')
        state.delete(previous_commit_sha)
      end
    else
      logger.info('Previous commit sha not found')
    end

    logger.info('Merging feature branch into stage')
    `git merge --squash --no-commit #{feature_branch}`
    `git commit --no-edit`
    head_sha = git.log(1).first.sha

    logger.info('Pushing to stage')
    git.push('origin', 'stage')

    logger.info("Persisting merged feature branch head sha: #{head_sha}")
    state.set(feature_branch, head_sha)
  ensure
    git.checkout(feature_branch)
  end

  private

  attr_reader :state, :git, :logger
end

logger = Logger.new(STDOUT)

state = State.new
state.hydrate!

boulder_dir = ENV.fetch('BOULDER_DIR')
git = Git.open(File.expand_path(boulder_dir), log: logger)
runner = Runner.new(state, git, logger)

begin
  runner.run!
ensure
  state.persist!
end
