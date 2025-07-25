#!/bin/bash

# Function to display usage
usage() {
    echo "Usage: .g <command> [arguments]"
    echo ""
    echo "Commands:"
    echo "  cl, clone <repo> [directory]    Clone a repository (tries git:, then https:)"
    echo "                                  (Works with full GitHub URLs including /blob/...)"
    echo "  i, init [-f]                    Initialize git repo, create initial commit"
    echo "                                  (-f: resets .git folder"
    echo "  cm, commit <message>            Commit with message (no quotes needed)"
    echo "  ac <message>                    Add all files and commit (no quotes needed)"
    echo "  acp <message>                   Add all files, commit, and push (no quotes needed)"
    echo "  p, push                         Push to remote"
    echo "  pl, pull                        Pull from remote"
    echo "  f, fetch                        Fetch from remote"
    echo "  b                               List branches"
    echo "  bc <branch-name>                Create and checkout new branch"
    echo "  bs <branch-name>                Switch to branch"
    echo "  bd <branch-name>                Delete branch"
    echo "  bm <branch-name>                Merge branch into current branch"
    echo "  ro <url>                        Set remote origin URL (just username/repo)"
    echo "  rs                              Reset soft (undo last commit, keep changes)"
    echo "  rh                              Reset hard (discard all changes)"
    echo "  rw                              Rewind - reset hard to previous commit (HEAD^1)"
    echo "  am <message>                    Amend last commit with new message"
    echo "  loc                             Show lines of code added/removed in past 24h"
    echo "  loc --all                       Compare your recent changes with historical changes"
    echo ""
    echo "Options:"
    echo "  -h, --help    Show this help message and exit"
    echo ""
    echo "Description:"
    echo "  Git commands shorthands."
    echo ""
    exit 1
}

# Function to handle clone command
handle_clone() {
    if [ -z "$1" ]; then
        echo "Error: Repository name is required"
        usage
    fi

    repo=$1
    
    # If repo is a full GitHub URL with blob or tree paths, extract just the org/repo part
    if [[ $repo == *"github.com"* ]]; then
        # Extract just the org/repo part from GitHub URLs
        # This handles URLs like:
        # - https://github.com/username/repo/blob/main/path/to/file
        # - https://github.com/username/repo/tree/main/path/to/dir
        # - https://github.com/username/repo
        repo=$(echo "$repo" | sed -E 's|https?://github.com/([^/]+/[^/]+).*|\1|')
    fi
    
    dir=${2:-$(basename "$repo" .git)}  # Use second argument as directory, or extract from repo name

    # If repo doesn't contain a full URL, assume it's a GitHub repository
    if [[ $repo != *"://"* ]]; then
        # Try SSH first
        if git clone "git@github.com:$repo.git" "$dir" 2>/dev/null; then
            echo "Successfully cloned using SSH"
            return 0
        fi
        
        echo "SSH clone failed, trying HTTPS..."
        # Try HTTPS if SSH fails
        if git clone "https://github.com/$repo.git" "$dir"; then
            echo "Successfully cloned using HTTPS"
            return 0
        fi
        
        echo "Failed to clone repository"
        return 1
    else
        # If it's a full URL, just use it directly
        git clone "$repo" "$dir"
    fi
}

# Function to handle init command
handle_init() {
    # Check for -f flag
    force_flag=false
    if [ "$1" = "-f" ]; then
        force_flag=true
        shift
    fi

    # If -f flag is present, delete .git folder if it exists
    if [ "$force_flag" = true ] && [ -d ".git" ]; then
        echo "Removing existing .git directory..."
        rm -rf .git
    fi

    # Check if .git directory exists and has commits
    if [ -d ".git" ] && [ "$force_flag" = false ]; then
        # Check if there are any commits
        if git rev-parse --verify HEAD &>/dev/null; then
            echo "Error: Repository already has commits. Use -f flag to reinitialize."
            return 1
        fi
    fi

    # Initialize git repository
    git init

    # Stage all files
    git add .

    # Create initial commit
    git commit -m "Initial commit"

    # Echo helpful instructions
    echo ""
    echo "Git repository initialized successfully!"
    echo ""
    echo "Next steps you might want to try:"
    echo "  .g ro username/repo    - Set up remote origin on GitHub"
    echo "  .g p                   - Push to remote"
    echo "  .g bc feature-branch   - Create a new branch"
    echo ""
}

# Function to handle commit command
handle_commit() {
    if [ -z "$1" ]; then
        echo "Error: Commit message is required"
        usage
    fi
    
    # Join all arguments as the commit message
    message="$*"
    git commit -m "$message"
}

# Function to handle add and commit command
handle_add_commit() {
    if [ -z "$1" ]; then
        echo "Error: Commit message is required"
        usage
    fi
    
    # Join all arguments as the commit message
    message="$*"
    git add .
    git commit -m "$message"
}

# Function to handle add, commit and push command
handle_add_commit_push() {
    if [ -z "$1" ]; then
        echo "Error: Commit message is required"
        usage
    fi
    
    # Join all arguments as the commit message
    message="$*"
    git add .
    git commit -m "$message"
    git push
}

# Function to handle push command
handle_push() {
    git push
}

# Function to handle pull command
handle_pull() {
    git pull
}

# Function to handle fetch command
handle_fetch() {
    git fetch
}

# Function to handle branch commands
handle_branch() {
    git branch
}

handle_branch_create() {
    if [ -z "$1" ]; then
        echo "Error: Branch name is required"
        usage
    fi
    
    git checkout -b "$1"
}

handle_branch_switch() {
    if [ -z "$1" ]; then
        echo "Error: Branch name is required"
        usage
    fi
    
    git checkout "$1"
}

handle_branch_delete() {
    if [ -z "$1" ]; then
        echo "Error: Branch name is required"
        usage
    fi
    
    git branch -D "$1"
}

handle_branch_merge() {
    if [ -z "$1" ]; then
        echo "Error: Branch name is required"
        usage
    fi
    
    git merge "$1"
}

# Function to handle remote origin URL
handle_remote_origin() {
    if [ -z "$1" ]; then
        echo "Error: GitHub repository (username/repo) is required"
        usage
    fi
    
    # Check if origin remote exists
    if git remote get-url origin &>/dev/null; then
        # Origin exists, update it
        git remote set-url origin "https://github.com/$1.git"
        echo "Updated remote origin URL https://github.com/$1"
    else
        # Origin doesn't exist, add it
        git remote add origin "https://github.com/$1.git"
        echo "Added remote origin URL https://github.com/$1"
    fi
}

# Function to handle reset commands
handle_reset_soft() {
    git reset --soft HEAD~1
}

handle_reset_hard() {
    git reset --hard HEAD
}

handle_reset_rewind() {
    # Get the commit message of the commit that will be removed
    commit_msg=$(git log -1 --pretty=%B HEAD)
    
    echo "WARNING: This will permanently remove the most recent commit:"
    echo "  \"$commit_msg\""
    echo "and discard all changes in your working directory."
    echo ""
    read -p "Are you sure you want to continue? (y/N): " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        git reset --hard HEAD^1
        echo "Successfully rewound to previous commit."
    else
        echo "Rewind operation cancelled."
    fi
}

# Function to handle amend commit
handle_amend_commit() {
    if [ -z "$1" ]; then
        echo "Error: New commit message is required"
        usage
    fi
    
    # Join all arguments as the commit message
    message="$*"
    git commit --amend -m "$message"
}

# Function to handle loc command
handle_loc() {
    # Check if --all flag is provided
    if [ "$1" = "--all" ]; then
        # Get current user's email
        current_user=$(git config user.email)
        
        # Get stats for current user (lifetime)
        your_stats=$(git log --numstat --author="$current_user" | awk '
            /^[0-9]/ {
                added += $1
                removed += $2
            }
            END {
                if (added > 0 || removed > 0) {
                    print "+" added " -" removed
                }
            }
        ')
        
        # Get stats for all other users in the repository history
        others_stats=$(git log --numstat --author="^(?!$current_user).*" | awk '
            /^[0-9]/ {
                added += $1
                removed += $2
            }
            END {
                if (added > 0 || removed > 0) {
                    print "+" added " -" removed
                }
            }
        ')
        
        echo "Your changes (lifetime):"
        if [ -z "$your_stats" ]; then
            echo "No changes"
        else
            echo "$your_stats"
        fi
        
        echo -e "\nHistorical changes (all other contributors):"
        if [ -z "$others_stats" ]; then
            echo "No changes"
        else
            echo "$others_stats"
        fi
    else
        # Original functionality for showing last 24h changes
        # Get the date 24 hours ago in ISO 8601 format
        since_date=$(date -v-24H +"%Y-%m-%d %H:%M:%S")
        
        # Run git log with --numstat to get the number of lines added/removed
        stats=$(git log --numstat --since="$since_date" | awk '
            /^[0-9]/ {
                added += $1
                removed += $2
            }
            END {
                print "+" added " -" removed
            }
        ')
        
        if [ -z "$stats" ]; then
            echo "No code changes in the past 24 hours"
        else
            echo "Lines of code changed in past 24h:"
            echo "$stats"
        fi
    fi
}

# Main command router
case "$1" in
    "cl"|"clone")
        shift
        handle_clone "$@"
        ;;
    "i"|"init")
        shift
        handle_init "$@"
        ;;
    "cm"|"commit")
        shift
        handle_commit "$@"
        ;;
    "ac")
        shift
        handle_add_commit "$@"
        ;;
    "acp")
        shift
        handle_add_commit_push "$@"
        ;;
    "p"|"push")
        handle_push
        ;;
    "pl"|"pull")
        handle_pull
        ;;
    "f"|"fetch")
        handle_fetch
        ;;
    "b")
        handle_branch
        ;;
    "bc")
        shift
        handle_branch_create "$@"
        ;;
    "bs")
        shift
        handle_branch_switch "$@"
        ;;
    "bd")
        shift
        handle_branch_delete "$@"
        ;;
    "bm")
        shift
        handle_branch_merge "$@"
        ;;
    "ro")
        shift
        handle_remote_origin "$@"
        ;;
    "rs")
        handle_reset_soft
        ;;
    "rh")
        handle_reset_hard
        ;;
    "rw")
        handle_reset_rewind
        ;;
    "am")
        shift
        handle_amend_commit "$@"
        ;;
    "loc")
        shift
        handle_loc "$@"
        ;;
    *)
        usage
        ;;
esac 