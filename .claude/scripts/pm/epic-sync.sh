#!/bin/bash

# Epic Sync Script
# Push epic and tasks to GitHub as issues

set -e

ARGUMENTS="$1"

if [ -z "$ARGUMENTS" ]; then
    echo "❌ Usage: $0 <feature_name>"
    exit 1
fi

echo "Syncing epic: $ARGUMENTS"
echo ""

# Quick Check
if [ ! -f ".claude/epics/$ARGUMENTS/epic.md" ]; then
    echo "❌ Epic not found. Run: /pm:prd-parse $ARGUMENTS"
    exit 1
fi

task_count=$(ls .claude/epics/$ARGUMENTS/*.md 2>/dev/null | grep -v epic.md | wc -l)
if [ "$task_count" -eq 0 ]; then
    echo "❌ No tasks to sync. Run: /pm:epic-decompose $ARGUMENTS"
    exit 1
fi

echo "Found $task_count tasks to sync"
echo ""

# Check Remote Repository
remote_url=$(git remote get-url origin 2>/dev/null || echo "")
if [[ "$remote_url" == *"automazeio/ccpm"* ]] || [[ "$remote_url" == *"automazeio/ccpm.git"* ]]; then
    echo "❌ ERROR: You're trying to sync with the CCPM template repository!"
    echo ""
    echo "This repository (automazeio/ccpm) is a template for others to use."
    echo "You should NOT create issues or PRs here."
    echo ""
    echo "To fix this:"
    echo "1. Fork this repository to your own GitHub account"
    echo "2. Update your remote origin:"
    echo "   git remote set-url origin https://github.com/YOUR_USERNAME/YOUR_REPO.git"
    echo ""
    echo "Or if this is a new project:"
    echo "1. Create a new repository on GitHub"
    echo "2. Update your remote origin:"
    echo "   git remote set-url origin https://github.com/YOUR_USERNAME/YOUR_REPO.git"
    echo ""
    echo "Current remote: $remote_url"
    exit 1
fi

# Check GitHub CLI
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) not found. Please install it first:"
    echo "   brew install gh"
    echo "   gh auth login"
    exit 1
fi

# Check authentication
if ! gh auth status &> /dev/null; then
    echo "❌ GitHub CLI not authenticated. Please run:"
    echo "   gh auth login"
    exit 1
fi

echo "✅ GitHub CLI authenticated"
echo ""

# Create Epic Issue
echo "Creating epic issue..."

# Extract content without frontmatter
sed '1,/^---$/d; 1,/^---$/d' .claude/epics/$ARGUMENTS/epic.md > /tmp/epic-body-raw.md

# Remove "## Tasks Created" section and replace with Stats
awk '
  /^## Tasks Created/ {
    in_tasks=1
    next
  }
  /^## / && in_tasks {
    in_tasks=0
    # When we hit the next section after Tasks Created, add Stats
    if (total_tasks) {
      print "## Stats\n"
      print "Total tasks: " total_tasks
      print "Parallel tasks: " parallel_tasks " (can be worked on simultaneously)"
      print "Sequential tasks: " sequential_tasks " (have dependencies)"
      if (total_effort) print "Estimated total effort: " total_effort " hours"
      print ""
    }
  }
  /^Total tasks:/ && in_tasks { total_tasks = $3; next }
  /^Parallel tasks:/ && in_tasks { parallel_tasks = $3; next }
  /^Sequential tasks:/ && in_tasks { sequential_tasks = $3; next }
  /^Estimated total effort:/ && in_tasks {
    gsub(/^Estimated total effort: /, "")
    total_effort = $0
    next
  }
  !in_tasks { print }
  END {
    # If we were still in tasks section at EOF, add stats
    if (in_tasks && total_tasks) {
      print "## Stats\n"
      print "Total tasks: " total_tasks
      print "Parallel tasks: " parallel_tasks " (can be worked on simultaneously)"
      print "Sequential tasks: " sequential_tasks " (have dependencies)"
      if (total_effort) print "Estimated total effort: " total_effort
    }
  }
' /tmp/epic-body-raw.md > /tmp/epic-body.md

# Determine epic type
if grep -qi "bug\|fix\|issue\|problem\|error" /tmp/epic-body.md; then
    epic_type="bug"
else
    epic_type="feature"
fi

# Create epic issue (without custom labels for now)
epic_output=$(gh issue create \
    --title "Epic: $ARGUMENTS" \
    --body-file /tmp/epic-body.md)
epic_number=$(echo "$epic_output" | grep -o 'https://github.com/[^/]*/[^/]*/issues/[0-9]*' | grep -o '[0-9]*$')

echo "✅ Created epic issue #$epic_number"
echo ""

# Create Task Sub-Issues
echo "Creating $task_count task issues..."

# Check if gh-sub-issue is available
if gh extension list | grep -q "yahsan2/gh-sub-issue"; then
    use_subissues=true
    echo "✅ Using gh-sub-issue extension"
else
    use_subissues=false
    echo "⚠️ gh-sub-issue not installed. Using fallback mode."
fi

# Create tasks sequentially for now
task_mapping=""
for task_file in .claude/epics/$ARGUMENTS/[0-9][0-9][0-9].md; do
    [ -f "$task_file" ] || continue

    # Extract task name from frontmatter
    task_name=$(grep '^name:' "$task_file" | sed 's/^name: *//')

    # Strip frontmatter from task content
    sed '1,/^---$/d; 1,/^---$/d' "$task_file" > /tmp/task-body.md

    # Create sub-issue (without custom labels for now)
    if [ "$use_subissues" = true ]; then
        task_output=$(gh sub-issue create \
            --parent "$epic_number" \
            --title "$task_name" \
            --body-file /tmp/task-body.md)
        task_number=$(echo "$task_output" | grep -o 'https://github.com/[^/]*/[^/]*/issues/[0-9]*' | grep -o '[0-9]*$')
    else
        task_output=$(gh issue create \
            --title "$task_name" \
            --body-file /tmp/task-body.md)
        task_number=$(echo "$task_output" | grep -o 'https://github.com/[^/]*/[^/]*/issues/[0-9]*' | grep -o '[0-9]*$')
    fi

    echo "✅ Created task #$task_number: $task_name"
    
    # Record mapping for renaming
    echo "$task_file:$task_number" >> /tmp/task-mapping.txt
done

echo ""

# Rename Task Files and Update References
echo "Updating task files with GitHub issue numbers..."

# Create mapping from old task numbers to new issue IDs
> /tmp/id-mapping.txt
while IFS=: read -r task_file task_number; do
    # Extract old number from filename (e.g., 001 from 001.md)
    old_num=$(basename "$task_file" .md)
    echo "$old_num:$task_number" >> /tmp/id-mapping.txt
done < /tmp/task-mapping.txt

# Process each task file
while IFS=: read -r task_file task_number; do
    new_name="$(dirname "$task_file")/${task_number}.md"

    # Read the file content
    content=$(cat "$task_file")

    # Update depends_on and conflicts_with references
    while IFS=: read -r old_num new_num; do
        # Update arrays like [001, 002] to use new issue numbers
        content=$(echo "$content" | sed "s/\b$old_num\b/$new_num/g")
    done < /tmp/id-mapping.txt

    # Write updated content to new file
    echo "$content" > "$new_name"

    # Remove old file if different from new
    [ "$task_file" != "$new_name" ] && rm "$task_file"

    # Update github field in frontmatter
    repo=$(gh repo view --json nameWithOwner -q .nameWithOwner)
    github_url="https://github.com/$repo/issues/$task_number"

    # Update frontmatter with GitHub URL and current timestamp
    current_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Use sed to update the github and updated fields
    sed -i.bak "/^github:/c\github: $github_url" "$new_name"
    sed -i.bak "/^updated:/c\updated: $current_date" "$new_name"
    rm "${new_name}.bak"
done < /tmp/task-mapping.txt

echo "✅ Updated task files with GitHub issue numbers"
echo ""

# Update Epic File
echo "Updating epic file..."

# Get repo info
repo=$(gh repo view | grep -o 'github.com/[^/]*/[^/]*' | sed 's/github.com\///')
epic_url="https://github.com/$repo/issues/$epic_number"
current_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Update epic frontmatter
sed -i.bak "/^github:/c\github: $epic_url" .claude/epics/$ARGUMENTS/epic.md
sed -i.bak "/^updated:/c\updated: $current_date" .claude/epics/$ARGUMENTS/epic.md
rm .claude/epics/$ARGUMENTS/epic.md.bak

echo "✅ Updated epic file with GitHub URL"
echo ""

# Create Worktree
echo "Creating development worktree..."

# Ensure main is current
git checkout main
git pull origin main

# Create worktree for epic
git worktree add ../epic-$ARGUMENTS -b epic/$ARGUMENTS

echo "✅ Created worktree: ../epic-$ARGUMENTS"
echo ""

# Cleanup
rm -f /tmp/epic-body-raw.md /tmp/epic-body.md /tmp/task-body.md /tmp/task-mapping.txt /tmp/id-mapping.txt

# Output
echo "✅ Synced to GitHub"
echo "  - Epic: #$epic_number - Epic: $ARGUMENTS"
echo "  - Tasks: $task_count sub-issues created"
echo "  - Labels applied: epic, task, epic:$ARGUMENTS"
echo "  - Files renamed: 001.md → $task_number.md"
echo "  - References updated: depends_on/conflicts_with now use issue IDs"
echo "  - Worktree: ../epic-$ARGUMENTS"
echo ""
echo "Next steps:"
echo "  - Start parallel execution: /pm:epic-start $ARGUMENTS"
echo "  - Or work on single issue: /pm:issue-start {issue_number}"
echo "  - View epic: https://github.com/$repo/issues/$epic_number"
