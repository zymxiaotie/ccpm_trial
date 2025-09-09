# CLAUDE.md

> Think carefully and implement the most concise solution that changes as little code as possible.

## USE SUB-AGENTS FOR CONTEXT OPTIMIZATION

### 1. Always use the file-analyzer sub-agent when asked to read files.
The file-analyzer agent is an expert in extracting and summarizing critical information from files, particularly log files and verbose outputs. It provides concise, actionable summaries that preserve essential information while dramatically reducing context usage.

### 2. Always use the code-analyzer sub-agent when asked to search code, analyze code, research bugs, or trace logic flow.

The code-analyzer agent is an expert in code analysis, logic tracing, and vulnerability detection. It provides concise, actionable summaries that preserve essential information while dramatically reducing context usage.

### 3. Always use the test-runner sub-agent to run tests and analyze the test results.

Using the test-runner agent ensures:

- Full test output is captured for debugging
- Main conversation stays clean and focused
- Context usage is optimized
- All issues are properly surfaced
- No approval dialogs interrupt the workflow

## Philosophy

### Error Handling

- **Fail fast** for critical configuration (missing text model)
- **Log and continue** for optional features (extraction model)
- **Graceful degradation** when external services unavailable
- **User-friendly messages** through resilience layer

### Testing

- Always use the test-runner agent to execute tests.
- Do not use mock services for anything ever.
- Do not move on to the next test until the current test is complete.
- If the test fails, consider checking if the test is structured correctly before deciding we need to refactor the codebase.
- Tests to be verbose so we can use them for debugging.


## Tone and Behavior

- Criticism is welcome. Please tell me when I am wrong or mistaken, or even when you think I might be wrong or mistaken.
- Please tell me if there is a better approach than the one I am taking.
- Please tell me if there is a relevant standard or convention that I appear to be unaware of.
- Be skeptical.
- Be concise.
- Short summaries are OK, but don't give an extended breakdown unless we are working through the details of a plan.
- Do not flatter, and do not give compliments unless I am specifically asking for your judgement.
- Occasional pleasantries are fine.
- Feel free to ask many questions. If you are in doubt of my intent, don't guess. Ask.

## ABSOLUTE RULES:

- NO PARTIAL IMPLEMENTATION
- NO SIMPLIFICATION : no "//This is simplified stuff for now, complete implementation would blablabla"
- NO CODE DUPLICATION : check existing codebase to reuse functions and constants Read files before writing new functions. Use common sense function name to find them easily.
- NO DEAD CODE : either use or delete from codebase completely
- IMPLEMENT TEST FOR EVERY FUNCTIONS
- NO CHEATER TESTS : test must be accurate, reflect real usage and be designed to reveal flaws. No useless tests! Design tests to be verbose so we can use them for debuging.
- NO INCONSISTENT NAMING - read existing codebase naming patterns.
- NO OVER-ENGINEERING - Don't add unnecessary abstractions, factory patterns, or middleware when simple functions would work. Don't think "enterprise" when you need "working"
- NO MIXED CONCERNS - Don't put validation logic inside API handlers, database queries inside UI components, etc. instead of proper separation
- NO RESOURCE LEAKS - Don't forget to close database connections, clear timeouts, remove event listeners, or clean up file handles

## **🔧 Let's Complete Git Setup First**

Since you have the Git configuration guide in your CLAUDE.md file, let's follow those steps:

### **Step 1: Configure Your Git Identity**

You need to run these commands in your terminal:

```bash
# Set your name (replace with your actual name)
git config --global user.name "May Zhang"

# Set your email (replace with your GitHub email)
git config --global user.email "your.email@example.com"
```

### **Step 2: Set Git Defaults**

```bash
# Set default branch to main
git config --global init.defaultBranch main

# Configure line endings for macOS
git config --global core.autocrlf input
```

### **Step 3: Verify Configuration**

```bash
# Check your configuration
git config --list
```

### **Step 4: Commit Your Current Work**

```bash
# Add all files
git add .

# Commit with a message
git commit -m "Initial CCPM setup with fintech data migration project"

# Check status
git status
```

### **Step 5: Push to GitHub**

```bash
# Push to GitHub
git push -u origin main
```

## **🎯 After Git Setup:**

Once you've completed the Git configuration and pushed your work, you can run:

```bash
<code_block_to_apply_changes_from>
```

This will:
- Create a GitHub issue for your epic
- Create 8 sub-issues for your tasks
- Set up proper issue relationships
- Enable the full CCPM workflow

## **❓ Questions:**

1. **What's your full name?** (for `git config --global user.name`)
2. **What email do you use with GitHub?** (for `git config --global user.email`)
3. **Have you run these Git commands yet?**

## **💡 Alternative Approach:**

If you want to skip GitHub sync for now, you can:

1. **Start working on Task #001** directly
2. **Use `/pm:epic-start my-first-feature`** to set up a worktree
3. **Complete Git setup later** when you're ready to sync

**What would you prefer to do?**
- Complete Git configuration first?
- Start working on tasks locally?
- Try a different approach?
