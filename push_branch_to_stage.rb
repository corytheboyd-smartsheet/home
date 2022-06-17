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
  def initialize(state, git, logger, dry_run)
    @state = state
    @git = git
    @logger = logger
    @dry_run = dry_run
  end

  def run!(feature_branch)
    if %w(master main stage).include?(feature_branch)
      logger.error("On protected branch: #{feature_branch}")
      exit 1
    end

    feature_branch_head_sha = git.log(1).first.sha
    logger.info("Running for feature branch: branch`#{feature_branch}` head=`#{feature_branch_head_sha}`")

    logger.info('Resetting local master branch to origin')
    git.branch('master').in_branch do
      git.reset_hard('origin/master')
    end

    stage_branch = git.branch('stage')
    stage_branch.checkout

    logger.info('Resetting local stage branch to origin')
    git.reset_hard('origin/stage')
    git.pull('origin', 'stage')

    logger.info('Merging master branch into stage')
    git.merge('origin/master')

    logger.info('Merging master onto stage')
    git.merge('master')

    logger.info('Cleaning up merged feature branch cherry-picks on stage')
    Util.git_deleted_feature_branches.each do |deleted_feature_branch|
      commit_sha = state.get(deleted_feature_branch)
      if commit_sha
        logger.warn("Revert cherry-pick for merged feature branch: branch=`#{deleted_feature_branch}` sha=`#{commit_sha}`")
        git.revert(commit_sha)
        state.delete(deleted_feature_branch)
      end
    end

    previous_commit_sha = state.get(feature_branch)
    if previous_commit_sha
      if stage_branch.contains?(previous_commit_sha)
        logger.info("Reverting previous feature branch cherry-pick: sha=`#{previous_commit_sha}`")
        git.revert(previous_commit_sha)
      else
        logger.warn("Previous cherry-pick was forcibly removed from stage: sha=`#{previous_commit_sha}`")
        state.delete(previous_commit_sha)
      end
    else
      logger.info('Previous commit sha not found')
    end

    logger.info('Cherry-picking current state of feature branch to stage')
    feature_branch_base = `git merge-base master #{feature_branch}`.strip
    `git cherry-pick --no-commit #{[feature_branch_base, feature_branch].join('..')}`
    git.commit("Cherry-pick of feature branch: #{feature_branch}")

    begin
      if dry_run
        logger.info('Skipping push to stage per dry run')
      else
        logger.info('Pushing to stage (TODO uncomment out, do not trust yet)')
        # git.push('origin', 'stage')
      end

      logger.info("Persisting merged feature branch head sha: #{head_sha}")
      state.set(feature_branch, head_sha)
    rescue => e
      logger.warn("Failed to push: #{e.message}")
      # Don't save SHA if it wasn't pushed
      state.delete(feature_branch)
    end
  end

  private

  attr_reader :state, :git, :logger, :dry_run
end

class Util
  class << self
    def git_deleted_feature_branches
      script = <<-SHELL
      git branch -vv | \
        grep ': gone]'| \
        grep -v "\*" | \
        awk '{ print $1; }' | \
        grep -E "^(?:[a-zA-Z0-9_-]+\/)(?:[a-zA-Z0-9_-]+\/?)+"
      SHELL
      `#{script}`.strip.split("\n").map(&:strip)
    end
  end
end

logger = Logger.new(STDOUT)
logger.level = Logger::INFO

state = State.new
state.hydrate!

boulder_dir = ENV.fetch('BOULDER_DIR')
dry_run = ENV.fetch('DRY_RUN', 'true') == 'true'

git = Git.open(File.expand_path(boulder_dir), log: logger)
runner = Runner.new(state, git, logger, dry_run)

feature_branch = git.current_branch

if dry_run
  logger.info("DRY RUN state will not persist and stage will not be pushed")
end

begin
  runner.run!(feature_branch)
ensure
  git.checkout(feature_branch)
  unless dry_run
    logger.info('Skipping state persist per dry run')
    state.persist!
  end
end
