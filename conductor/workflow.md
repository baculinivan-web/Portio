# Project Workflow

## Guiding Principles

1. **The Plan is the Source of Truth:** All work must be tracked in `plan.md`
2. **The Tech Stack is Deliberate:** Changes to the tech stack must be documented in `tech-stack.md` *before* implementation
3. **Test-Driven Development:** Write unit tests for critical business logic before implementation
4. **Targeted Code Coverage:** Aim for >20% code coverage, focusing on core nutritional calculations and data processing logic.
5. **User Experience & Verification First:** Every decision should prioritize user experience. Prioritize manual user verification for UI and complex AI interactions.
6. **Non-Interactive & CI-Aware:** Prefer non-interactive commands. Use `CI=true` for watch-mode tools (tests, linters) to ensure single execution.

## Task Workflow

All tasks follow a strict lifecycle:

### Standard Task Workflow

1. **Select Task:** Choose the next available task from `plan.md` in sequential order

2. **Mark In Progress:** Before beginning work, edit `plan.md` and change the task from `[ ]` to `[~]`

3. **Identify Critical Logic:** Determine if the task involves core nutritional calculations or critical data processing that requires unit tests.

4. **Write Tests for Critical Logic (Optional/Targeted):**
   - If critical logic is identified, create or update a test file.
   - Write unit tests that clearly define the expected behavior.
   - Run the tests and confirm they fail (Red Phase).

5. **Implement Feature/Fix:**
   - Write the application code to fulfill the task requirements and make any tests pass.
   - Run the test suite if applicable.

6. **Verify Implementation:**
   - For UI changes, perform manual verification on the simulator or device.
   - For AI/Logic changes, verify with sample inputs.

7. **Document Deviations:** If implementation differs from tech stack:
   - **STOP** implementation
   - Update `tech-stack.md` with new design
   - Add dated note explaining the change
   - Resume implementation

8. **Commit Code Changes:**
   - Stage all code changes related to the task.
   - Propose a clear, concise commit message e.g, `feat(ui): Create basic HTML structure for calculator`.
   - Perform the commit.

9. **Attach Task Summary with Git Notes:**
   - **Step 9.1: Get Commit Hash:** Obtain the hash of the *just-completed commit* (`git log -1 --format="%H"`).
   - **Step 9.2: Draft Note Content:** Create a detailed summary for the completed task. This should include the task name, a summary of changes, a list of all created/modified files, and the core "why" for the change.
   - **Step 9.3: Attach Note:** Use the `git notes` command to attach the summary to the commit.
     ```bash
     git notes add -m "<note content>" <commit_hash>
     ```

10. **Get and Record Task Commit SHA:**
    - **Step 10.1: Update Plan:** Read `plan.md`, find the line for the completed task, update its status from `[~]` to `[x]`, and append the first 7 characters of the *just-completed commit's* commit hash.
    - **Step 10.2: Write Plan:** Write the updated content back to `plan.md`.

11. **Commit Plan Update:**
    - **Action:** Stage the modified `plan.md` file.
    - **Action:** Commit this change with a descriptive message (e.g., `conductor(plan): Mark task 'Create user model' as complete`).

### Phase Completion Verification and Checkpointing Protocol

**Trigger:** This protocol is executed immediately after a task is completed that also concludes a phase in `plan.md`.

1.  **Announce Protocol Start:** Inform the user that the phase is complete and the verification and checkpointing protocol has begun.

2.  **Determine Phase Scope:** 
    -   Find the Git commit SHA of the *previous* phase's checkpoint.
    -   Execute `git diff --name-only <previous_checkpoint_sha> HEAD` to list changed files.

3.  **Execute Targeted Automated Tests:**
    -   Run the automated test suite.
    -   If tests fail, debugging is required (max two attempts).

4.  **Propose a Detailed Manual Verification Plan (High Priority):**
    -   **CRITICAL:** Generate a step-by-step plan for the user to verify the user-facing goals of the completed phase.
    -   The plan must follow the prescribed format (Frontend/Backend).

5.  **Await Explicit User Feedback:**
    -   Ask: "**Does this meet your expectations? Please confirm with yes or provide feedback on what needs to be changed.**"
    -   **PAUSE** and await the user's response. Do not proceed without an explicit yes or confirmation.

6.  **Create Checkpoint Commit:**
    -   Stage all changes.
    -   Perform the commit: `conductor(checkpoint): Checkpoint end of Phase X`.

7.  **Attach Auditable Verification Report using Git Notes:**
    -   Draft a report including test results and user confirmation.
    -   Attach to the checkpoint commit using `git notes`.

8.  **Get and Record Phase Checkpoint SHA:**
    -   Update `plan.md` with the checkpoint SHA.

9. **Commit Plan Update:**
    -   Commit the plan update: `conductor(plan): Mark phase '<PHASE NAME>' as complete`.

10.  **Announce Completion:** Inform the user that the phase is complete and the checkpoint created.

## Definition of Done

A task is complete when:

1. All code implemented to specification.
2. Targeted unit tests written and passing (if applicable).
3. Manual verification performed and successful.
4. Documentation updated if needed.
5. Changes committed with proper message.
6. Git note with task summary attached.