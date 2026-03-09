#!/usr/bin/env python3
"""
create_roadmap_issues.py

Creates GitHub milestones, labels, issues and a GitHub Project v2 with
Sprint iterations from docs/Roadmap-demo.md.

Prerequisites
-------------
- The ``gh`` CLI must be authenticated (GITHUB_TOKEN env var).
- Run from any directory; pass ``--repo owner/repo`` or set GH_REPO.

Usage
-----
  python3 .github/scripts/create_roadmap_issues.py --repo woodbase/Xeno-breach
"""

import argparse
import datetime
import json
import subprocess
import sys

# ---------------------------------------------------------------------------
# Roadmap data derived from docs/Roadmap-demo.md
# ---------------------------------------------------------------------------

MILESTONES = [
    {
        "number_key": "M1",
        "title": "Milestone 1 \u2013 Core FPS Framework",
        "description": (
            "Goal: Establish stable FPS gameplay. Priority: Critical"
        ),
    },
    {
        "number_key": "M2",
        "title": "Milestone 2 \u2013 Combat & Feedback",
        "description": "Goal: Make combat feel satisfying. Priority: High",
    },
    {
        "number_key": "M3",
        "title": "Milestone 3 \u2013 Level Design",
        "description": (
            "Goal: Create one complete playable level. Priority: Critical"
        ),
    },
    {
        "number_key": "M4",
        "title": "Milestone 4 \u2013 UI / UX",
        "description": "Goal: Create a clean FPS interface. Priority: High",
    },
    {
        "number_key": "M5",
        "title": "Milestone 5 \u2013 Mission / Quest Architecture",
        "description": (
            "Goal: Prepare the game for story-driven missions. Priority: Medium. "
            "Note: full quests not required for demo but architecture must be ready."
        ),
    },
    {
        "number_key": "M6",
        "title": "Milestone 6 \u2013 Game Polish",
        "description": (
            "Goal: Make the demo feel like a finished game slice. Priority: High"
        ),
    },
    {
        "number_key": "M7",
        "title": "Milestone 7 \u2013 Packaging & Release",
        "description": (
            "Goal: Prepare demo for distribution. Priority: Medium"
        ),
    },
    {
        "number_key": "M8",
        "title": "Future Milestones \u2013 Post Demo",
        "description": (
            "Not required for demo. Planned for future expansion."
        ),
    },
]

LABELS = [
    ("priority: critical", "d73a4a", "Must be done for the demo"),
    ("priority: high",     "e4e669", "High priority"),
    ("priority: medium",   "0075ca", "Medium priority"),
    ("priority: low",      "cfd3d7", "Low priority / post-demo"),
    ("post-demo",          "bfd4f2", "Future / post-demo work"),
    ("story points: 3",    "f9d0c4", "3 story points"),
    ("story points: 5",    "fef2c0", "5 story points"),
    ("story points: 8",    "c2e0c6", "8 story points"),
]

# sprint_key determines which Sprint iteration the issue belongs to.
ISSUES = [
    # ------------------------------------------------------------------ M1
    {
        "milestone_key": "M1",
        "sprint_key": "Sprint 1",
        "labels": ["priority: critical", "story points: 5"],
        "title": "Player Controller",
        "body": """\
## Player Controller

**Story Points:** 5
**Priority:** Critical
**Milestone:** Milestone 1 \u2013 Core FPS Framework

### Tasks
- [ ] FPS camera
- [ ] Mouse look
- [ ] Player movement (WASD)
- [ ] Sprint
- [ ] Jump (optional)
- [ ] Collision handling
- [ ] Player health system
- [ ] Damage feedback
- [ ] Death state
""",
    },
    {
        "milestone_key": "M1",
        "sprint_key": "Sprint 1",
        "labels": ["priority: critical", "story points: 8"],
        "title": "Weapon System (Modular)",
        "body": """\
## Weapon System (Modular)

**Story Points:** 8
**Priority:** Critical
**Milestone:** Milestone 1 \u2013 Core FPS Framework

### Tasks
- [ ] Weapon base class
- [ ] Firing system
- [ ] Hitscan or projectile system
- [ ] Fire rate / cooldown
- [ ] Ammo system
- [ ] Reload system
- [ ] Impact effects

### Architecture Must Support
- Multiple weapons
- Weapon upgrades
- Different firing modes
- Weapon switching

### Demo Weapon
- Basic rifle or pistol
""",
    },
    {
        "milestone_key": "M1",
        "sprint_key": "Sprint 1",
        "labels": ["priority: critical", "story points: 8"],
        "title": "Enemy Framework",
        "body": """\
## Enemy Framework

**Story Points:** 8
**Priority:** Critical
**Milestone:** Milestone 1 \u2013 Core FPS Framework

### Tasks
- [ ] Enemy base class
- [ ] Enemy health
- [ ] Damage system
- [ ] Enemy death state
- [ ] Basic enemy AI

### AI Behaviours
- [ ] Patrol or idle
- [ ] Detect player
- [ ] Chase player
- [ ] Melee or close-range attack

### Demo Enemy
- Xeno Crawler
""",
    },
    # ------------------------------------------------------------------ M2
    {
        "milestone_key": "M2",
        "sprint_key": "Sprint 2",
        "labels": ["priority: high", "story points: 5"],
        "title": "Combat Feedback",
        "body": """\
## Combat Feedback

**Story Points:** 5
**Priority:** High
**Milestone:** Milestone 2 \u2013 Combat & Feedback

### Tasks
- [ ] Hit effects
- [ ] Enemy damage reaction
- [ ] Screen damage effect
- [ ] Weapon recoil
- [ ] Basic muzzle flash
""",
    },
    {
        "milestone_key": "M2",
        "sprint_key": "Sprint 2",
        "labels": ["priority: high", "story points: 5"],
        "title": "Sound System",
        "body": """\
## Sound System

**Story Points:** 5
**Priority:** High
**Milestone:** Milestone 2 \u2013 Combat & Feedback

### Tasks
- [ ] Weapon firing sound
- [ ] Enemy sounds
- [ ] Player damage sound
- [ ] Ambient level sound
- [ ] UI sounds

> Use placeholder sounds if necessary.
""",
    },
    # ------------------------------------------------------------------ M3
    {
        "milestone_key": "M3",
        "sprint_key": "Sprint 2",
        "labels": ["priority: critical", "story points: 5"],
        "title": "Level Architecture",
        "body": """\
## Level Architecture

**Story Points:** 5
**Priority:** Critical
**Milestone:** Milestone 3 \u2013 Level Design

### Tasks
- [ ] Level scene structure
- [ ] Modular room layout
- [ ] Enemy spawn system
- [ ] Environmental collisions
- [ ] Navigation zones
""",
    },
    {
        "milestone_key": "M3",
        "sprint_key": "Sprint 2",
        "labels": ["priority: critical", "story points: 5"],
        "title": "Level Gameplay",
        "body": """\
## Level Gameplay

**Story Points:** 5
**Priority:** Critical
**Milestone:** Milestone 3 \u2013 Level Design

### Tasks
- [ ] Player start location
- [ ] Enemy encounters
- [ ] Level progression path
- [ ] Environmental storytelling
""",
    },
    {
        "milestone_key": "M3",
        "sprint_key": "Sprint 2",
        "labels": ["priority: critical", "story points: 3"],
        "title": "Level Completion",
        "body": """\
## Level Completion

**Story Points:** 3
**Priority:** Critical
**Milestone:** Milestone 3 \u2013 Level Design

### Tasks
- [ ] Exit trigger
- [ ] Victory screen
- [ ] Demo completion screen
""",
    },
    # ------------------------------------------------------------------ M4
    {
        "milestone_key": "M4",
        "sprint_key": "Sprint 3",
        "labels": ["priority: high", "story points: 5"],
        "title": "HUD",
        "body": """\
## HUD

**Story Points:** 5
**Priority:** High
**Milestone:** Milestone 4 \u2013 UI / UX

### HUD Elements
- [ ] Player health
- [ ] Ammo
- [ ] Current weapon
- [ ] Crosshair
- [ ] Damage indicator
""",
    },
    {
        "milestone_key": "M4",
        "sprint_key": "Sprint 3",
        "labels": ["priority: high", "story points: 5"],
        "title": "Menu System",
        "body": """\
## Menu System

**Story Points:** 5
**Priority:** High
**Milestone:** Milestone 4 \u2013 UI / UX

### Tasks
- [ ] Main menu
- [ ] Start game
- [ ] Restart level
- [ ] Quit game
""",
    },
    # ------------------------------------------------------------------ M5
    {
        "milestone_key": "M5",
        "sprint_key": "Sprint 3",
        "labels": ["priority: medium", "story points: 8"],
        "title": "Mission / Quest Architecture",
        "body": """\
## Mission / Quest Architecture

**Story Points:** 8
**Priority:** Medium
**Milestone:** Milestone 5 \u2013 Mission / Quest Architecture

> **Note:** The demo does NOT require full quests, but the system must be prepared.

### Tasks
- [ ] Mission manager system
- [ ] Objective structure
- [ ] Event triggers
- [ ] Mission completion tracking

### Examples of Future Missions
- Reach area
- Kill enemy group
- Activate terminal
- Retrieve item
""",
    },
    # ------------------------------------------------------------------ M6
    {
        "milestone_key": "M6",
        "sprint_key": "Sprint 4",
        "labels": ["priority: high", "story points: 5"],
        "title": "Visual Polish",
        "body": """\
## Visual Polish

**Story Points:** 5
**Priority:** High
**Milestone:** Milestone 6 \u2013 Game Polish

### Tasks
- [ ] Basic lighting
- [ ] Environment textures
- [ ] Weapon model polish
- [ ] Enemy model polish
""",
    },
    {
        "milestone_key": "M6",
        "sprint_key": "Sprint 4",
        "labels": ["priority: high", "story points: 3"],
        "title": "Performance",
        "body": """\
## Performance

**Story Points:** 3
**Priority:** High
**Milestone:** Milestone 6 \u2013 Game Polish

### Tasks
- [ ] FPS stability
- [ ] Collision optimization
- [ ] Enemy logic optimization
""",
    },
    {
        "milestone_key": "M6",
        "sprint_key": "Sprint 4",
        "labels": ["priority: high", "story points: 5"],
        "title": "Demo Experience",
        "body": """\
## Demo Experience

**Story Points:** 5
**Priority:** High
**Milestone:** Milestone 6 \u2013 Game Polish

### Tasks
- [ ] Intro text or screen
- [ ] Short story introduction
- [ ] Demo end screen
- [ ] "Wishlist / Follow development" message
""",
    },
    # ------------------------------------------------------------------ M7
    {
        "milestone_key": "M7",
        "sprint_key": "Sprint 4",
        "labels": ["priority: medium", "story points: 3"],
        "title": "Build & Distribution",
        "body": """\
## Build & Distribution

**Story Points:** 3
**Priority:** Medium
**Milestone:** Milestone 7 \u2013 Packaging & Release

### Tasks
- [ ] Export build
- [ ] Create itch.io page
- [ ] Screenshots
- [ ] Gameplay GIF
- [ ] Description text
""",
    },
    # ------------------------------------------------------------------ M8 (post-demo)
    {
        "milestone_key": "M8",
        "sprint_key": "Backlog",
        "labels": ["post-demo", "priority: low"],
        "title": "Weapons Expansion",
        "body": """\
## Weapons Expansion

**Milestone:** Future Milestones \u2013 Post Demo

### Planned Features
- [ ] Additional weapons
- [ ] Weapon upgrades
- [ ] Alternate fire modes
""",
    },
    {
        "milestone_key": "M8",
        "sprint_key": "Backlog",
        "labels": ["post-demo", "priority: low"],
        "title": "Enemy Expansion",
        "body": """\
## Enemy Expansion

**Milestone:** Future Milestones \u2013 Post Demo

### Planned Features
- [ ] Ranged enemies
- [ ] Elite enemies
- [ ] Boss encounters
""",
    },
    {
        "milestone_key": "M8",
        "sprint_key": "Backlog",
        "labels": ["post-demo", "priority: low"],
        "title": "Story System",
        "body": """\
## Story System

**Milestone:** Future Milestones \u2013 Post Demo

### Planned Features
- [ ] Full mission system
- [ ] Dialogue
- [ ] Story events
""",
    },
    {
        "milestone_key": "M8",
        "sprint_key": "Backlog",
        "labels": ["post-demo", "priority: low"],
        "title": "Level Expansion",
        "body": """\
## Level Expansion

**Milestone:** Future Milestones \u2013 Post Demo

### Planned Features
- [ ] Multiple levels
- [ ] Biomes
- [ ] Environmental hazards
""",
    },
]

# Sprint definitions: title → description
SPRINTS = [
    "Sprint 1 \u2013 Core FPS Framework",
    "Sprint 2 \u2013 Combat, Feedback & Level Design",
    "Sprint 3 \u2013 UI/UX & Quest Architecture",
    "Sprint 4 \u2013 Polish & Release",
    "Backlog \u2013 Post Demo",
]

# Map sprint_key prefix → full sprint title
SPRINT_KEY_MAP = {
    "Sprint 1": "Sprint 1 \u2013 Core FPS Framework",
    "Sprint 2": "Sprint 2 \u2013 Combat, Feedback & Level Design",
    "Sprint 3": "Sprint 3 \u2013 UI/UX & Quest Architecture",
    "Sprint 4": "Sprint 4 \u2013 Polish & Release",
    "Backlog":  "Backlog \u2013 Post Demo",
}


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def gh(*args, input_data=None, check=True):
    """Run a ``gh`` CLI command and return decoded stdout."""
    cmd = ["gh"] + list(args)
    result = subprocess.run(
        cmd,
        input=input_data,
        capture_output=True,
        text=True,
    )
    if check and result.returncode != 0:
        print(f"  ERROR running: {' '.join(cmd)}", file=sys.stderr)
        print(f"  stdout: {result.stdout.strip()}", file=sys.stderr)
        print(f"  stderr: {result.stderr.strip()}", file=sys.stderr)
        sys.exit(1)
    return result.stdout.strip()


def gh_json(*args, **kwargs):
    """Run a ``gh`` command and parse JSON output."""
    return json.loads(gh(*args, **kwargs))


def graphql(query: str, **variables):
    """Run a GraphQL query/mutation via ``gh api graphql``.

    Returns the parsed response dict. The caller should check for
    ``errors`` keys or missing ``data`` before accessing nested fields.
    """
    args = ["api", "graphql", "-f", f"query={query}"]
    for k, v in variables.items():
        args += ["-f", f"{k}={v}"]
    raw = gh(*args, check=False)
    if not raw:
        return {}
    try:
        return json.loads(raw)
    except json.JSONDecodeError as exc:
        print(
            f"  WARN: Could not parse GraphQL response as JSON: {exc}",
            file=sys.stderr,
        )
        return {}


# ---------------------------------------------------------------------------
# Steps
# ---------------------------------------------------------------------------

def create_labels(repo: str):
    print("\n=== Creating labels ===")
    for name, color, description in LABELS:
        result = subprocess.run(
            ["gh", "api", f"repos/{repo}/labels",
             "--method", "POST",
             "--field", f"name={name}",
             "--field", f"color={color}",
             "--field", f"description={description}"],
            capture_output=True, text=True,
        )
        if result.returncode == 0:
            print(f"  Created label: {name}")
        else:
            # 422 = already exists, which is fine
            print(f"  Label already exists (skipped): {name}")


def create_milestones(repo: str) -> dict:
    """Create milestones and return a mapping of number_key → milestone number."""
    print("\n=== Creating milestones ===")
    mapping: dict[str, int] = {}
    for ms in MILESTONES:
        result = subprocess.run(
            ["gh", "api", f"repos/{repo}/milestones",
             "--method", "POST",
             "--field", f"title={ms['title']}",
             "--field", f"description={ms['description']}",
             "--field", "state=open"],
            capture_output=True, text=True,
        )
        if result.returncode == 0:
            number = json.loads(result.stdout)["number"]
            print(f"  Created milestone #{number}: {ms['title']}")
        else:
            # Fall back to reading the existing milestone using Python-side
            # filtering to avoid embedding the title in a jq expression.
            existing_result = subprocess.run(
                ["gh", "api", f"repos/{repo}/milestones"],
                capture_output=True, text=True,
            )
            if existing_result.returncode != 0:
                raise RuntimeError(
                    f"Failed to list milestones for repo {repo}: "
                    f"{existing_result.stderr.strip()}"
                )
            try:
                all_milestones = json.loads(existing_result.stdout)
            except json.JSONDecodeError as exc:
                raise RuntimeError(
                    f"Unable to parse milestones JSON for repo {repo}"
                ) from exc
            existing = next(
                (m for m in all_milestones if m.get("title") == ms["title"]),
                None,
            )
            if existing is None:
                raise RuntimeError(
                    f"Milestone with title '{ms['title']}' not found in repo {repo}"
                )
            number = existing["number"]
            print(f"  Milestone already exists #{number}: {ms['title']}")
        mapping[ms["number_key"]] = number
    return mapping


def create_issues(repo: str, milestone_map: dict) -> list[tuple[int, str]]:
    """Create all issues; skip any that already exist (by title).

    Returns a list of ``(issue_number, sprint_key)`` pairs so that
    sprint assignment is never positionally derived and cannot go out of
    sync when individual issue creations fail.

    Existing issues are still included in the returned list so that they
    are added to the project and assigned to the correct sprint even when
    the script is re-run.
    """
    print("\n=== Creating issues ===")

    # Fetch ALL existing open issues (paginated) so deduplication is complete
    # even in repositories with many issues.
    existing_issues: dict[str, int] = {}  # title -> issue number
    existing_result = subprocess.run(
        ["gh", "issue", "list", "--repo", repo,
         "--state", "open", "--paginate", "--json", "title,number"],
        capture_output=True, text=True,
    )
    if existing_result.returncode == 0 and existing_result.stdout.strip():
        try:
            for item in json.loads(existing_result.stdout):
                existing_issues[item.get("title", "")] = item.get("number", 0)
        except json.JSONDecodeError:
            pass

    created: list[tuple[int, str]] = []
    for issue in ISSUES:
        if issue["title"] in existing_issues:
            existing_number = existing_issues[issue["title"]]
            print(f"  Issue already exists #{existing_number} (skipped): {issue['title']}")
            # Still include in returned pairs so sprint assignment is applied.
            created.append((existing_number, issue["sprint_key"]))
            continue
        ms_number = milestone_map.get(issue["milestone_key"])
        if ms_number is None:
            print(
                f"  WARN: No milestone found for key '{issue['milestone_key']}', "
                f"skipping issue '{issue['title']}'",
                file=sys.stderr,
            )
            continue
        label_str = ",".join(issue["labels"])
        result = subprocess.run(
            ["gh", "issue", "create",
             "--repo", repo,
             "--milestone", str(ms_number),
             "--label", label_str,
             "--title", issue["title"],
             "--body", issue["body"]],
            capture_output=True, text=True,
        )
        if result.returncode == 0:
            # Output is the issue URL, e.g. https://github.com/owner/repo/issues/42
            url = result.stdout.strip()
            number = int(url.rstrip("/").split("/")[-1])
            created.append((number, issue["sprint_key"]))
            print(f"  Created issue #{number}: {issue['title']}")
        else:
            print(
                f"  WARN: Failed to create issue '{issue['title']}': "
                f"{result.stderr.strip()}",
                file=sys.stderr,
            )
    return created


def create_project(owner: str) -> tuple[str, int]:
    """Create a GitHub Project v2 (or return the existing one) and return (project_id, project_number)."""
    print("\n=== Creating GitHub Project v2 ===")
    PROJECT_TITLE = "Xeno Breach \u2013 Roadmap to Playable Demo"

    # Resolve owner node ID
    resp = graphql(
        "query($login:String!){ repositoryOwner(login:$login){ id } }",
        login=owner,
    )
    owner_id = (
        resp.get("data", {})
        .get("repositoryOwner", {})
        .get("id")
    )
    if not owner_id:
        errors = resp.get("errors", resp)
        print(f"  ERROR: Could not resolve owner id for '{owner}': {errors}", file=sys.stderr)
        sys.exit(1)

    # Check whether a project with this name already exists to avoid duplicates.
    resp_check = graphql(
        """query($login:String!){
          repositoryOwner(login:$login){
            ... on User         { projectsV2(first:20){ nodes{ id number title } } }
            ... on Organization { projectsV2(first:20){ nodes{ id number title } } }
          }
        }""",
        login=owner,
    )
    existing_nodes = (
        resp_check.get("data", {})
        .get("repositoryOwner", {})
        .get("projectsV2", {})
        .get("nodes", [])
    )
    for node in existing_nodes:
        if node and node.get("title") == PROJECT_TITLE:
            project_id = node["id"]
            project_number = node["number"]
            print(f"  Project already exists #{project_number} (id: {project_id})")
            return project_id, project_number

    resp = graphql(
        """mutation($ownerId:ID!,$title:String!){
          createProjectV2(input:{ownerId:$ownerId,title:$title}){
            projectV2{ id number }
          }
        }""",
        ownerId=owner_id,
        title=PROJECT_TITLE,
    )
    if resp.get("errors"):
        print(
            f"  ERROR: GraphQL errors during project creation: {resp['errors']}",
            file=sys.stderr,
        )
        sys.exit(1)
    project = (
        resp.get("data", {})
        .get("createProjectV2", {})
        .get("projectV2")
    )
    if not project:
        print(
            f"  ERROR: Could not create project: unexpected response {resp}",
            file=sys.stderr,
        )
        sys.exit(1)
    project_id = project["id"]
    project_number = project["number"]
    print(f"  Created project #{project_number} (id: {project_id})")
    return project_id, project_number


def add_iteration_field(project_id: str) -> str:
    """Add a Sprint iteration field and return its field ID."""
    print("\n=== Adding Sprint iteration field ===")
    resp = graphql(
        """mutation($pid:ID!){
          addProjectV2Field(input:{
            projectId:$pid, dataType:ITERATION, name:"Sprint"
          }){
            projectV2Field{
              ... on ProjectV2IterationField{
                id
                configuration{ iterations{ id title startDate duration } }
              }
            }
          }
        }""",
        pid=project_id,
    )
    field = (
        resp.get("data", {})
        .get("addProjectV2Field", {})
        .get("projectV2Field")
    )
    if not field or not field.get("id"):
        errors = resp.get("errors", resp)
        print(f"  ERROR: Could not create Sprint field: {errors}", file=sys.stderr)
        sys.exit(1)
    field_id = field["id"]
    auto_iters = field.get("configuration", {}).get("iterations", [])
    print(f"  Sprint field id: {field_id}")
    print(f"  Auto-created iterations: {[i['title'] for i in auto_iters]}")
    return field_id


def configure_iterations(project_id: str, field_id: str) -> dict[str, str]:
    """Configure all sprint iterations in one API call.

    The GitHub Projects v2 ``iterationConfiguration.iterations`` array is a
    **replacement** list, not an append list — every call overwrites whatever
    was there before.  This function therefore collects all desired iterations
    and issues a single ``updateProjectV2Field`` mutation so that all five
    sprints end up in the field.

    Returns a mapping of full sprint title → iteration_id.
    """
    print("\n=== Configuring Sprint iterations ===")
    today = datetime.date.today().isoformat()

    # Query the auto-created iteration(s) so we can reuse their IDs.
    resp = graphql(
        """query($pid:ID!,$fname:String!){
          node(id:$pid){
            ... on ProjectV2{
              field(name:$fname){
                ... on ProjectV2IterationField{
                  id
                  configuration{ iterations{ id title } }
                }
              }
            }
          }
        }""",
        pid=project_id,
        fname="Sprint",
    )
    existing = (
        resp.get("data", {})
        .get("node", {})
        .get("field", {})
        .get("configuration", {})
        .get("iterations", [])
    )

    # Build the complete iteration list: reuse auto-created IDs for the first
    # N sprints, leave new ones without an id so GitHub creates them.
    # All five sprints are collected here and sent in ONE mutation call so
    # that no earlier entry is overwritten by a later one.
    #
    # Use json.dumps() to produce a properly escaped JSON string literal for
    # each title (handles backslashes, newlines, unicode, etc.) then strip
    # the surrounding double-quotes since we embed it in the GraphQL value.
    iter_parts: list[str] = []
    for idx, full_title in enumerate(SPRINTS):
        safe_title = json.dumps(full_title)[1:-1]  # inner content, without outer quotes
        if idx < len(existing):
            iter_id = existing[idx]["id"]
            iter_parts.append(
                f'{{id:"{iter_id}", title:"{safe_title}", '
                f'startDate:"{today}", duration:14}}'
            )
        else:
            iter_parts.append(f'{{title:"{safe_title}", duration:14}}')

    iterations_gql = "[" + ", ".join(iter_parts) + "]"

    resp2 = graphql(
        f"""mutation($pid:ID!,$fid:ID!){{
          updateProjectV2Field(input:{{
            projectId:$pid, fieldId:$fid,
            iterationConfiguration:{{
              duration:14, startDay:1,
              iterations:{iterations_gql},
              completedIterations:[]
            }}
          }}){{
            projectV2Field{{
              ... on ProjectV2IterationField{{
                configuration{{ iterations{{ id title }} }}
              }}
            }}
          }}
        }}""",
        pid=project_id,
        fid=field_id,
    )
    final_iters = (
        resp2.get("data", {})
        .get("updateProjectV2Field", {})
        .get("projectV2Field", {})
        .get("configuration", {})
        .get("iterations", [])
    )

    sprint_id_map: dict[str, str] = {}
    for it in final_iters:
        sprint_id_map[it["title"]] = it["id"]
        print(f"  Configured iteration: {it['title']} (id: {it['id']})")

    if not sprint_id_map:
        print("  WARN: No iterations returned after configuration", file=sys.stderr)

    return sprint_id_map


def add_issues_to_project(
    repo: str,
    project_id: str,
    field_id: str,
    sprint_id_map: dict[str, str],
    issue_sprint_pairs: list[tuple[int, str]],
):
    """Add every issue to the project and assign it to the correct sprint.

    ``issue_sprint_pairs`` is a list of ``(issue_number, sprint_key)`` tuples
    returned by :func:`create_issues`, so the sprint assignment is always
    explicit and never derived from list position.
    """
    print("\n=== Adding issues to project and assigning sprints ===")

    for issue_num, sprint_key in issue_sprint_pairs:
        sprint_full = SPRINT_KEY_MAP.get(sprint_key, "")

        # Get issue node ID
        node_id = gh(
            "api", f"repos/{repo}/issues/{issue_num}",
            "--jq", ".node_id",
        )

        # Add to project
        resp = graphql(
            """mutation($pid:ID!,$cid:ID!){
              addProjectV2ItemById(input:{projectId:$pid,contentId:$cid}){
                item{ id }
              }
            }""",
            pid=project_id,
            cid=node_id,
        )
        item_id = (
            resp.get("data", {})
            .get("addProjectV2ItemById", {})
            .get("item", {})
            .get("id")
        )
        if not item_id:
            print(
                f"  WARN: Could not add issue #{issue_num} to project",
                file=sys.stderr,
            )
            continue

        # Assign sprint
        iter_id = sprint_id_map.get(sprint_full)
        if iter_id:
            graphql(
                """mutation($pid:ID!,$iid:ID!,$fid:ID!,$vid:String!){
                  updateProjectV2ItemFieldValue(input:{
                    projectId:$pid, itemId:$iid, fieldId:$fid,
                    value:{iterationId:$vid}
                  }){ projectV2Item{ id } }
                }""",
                pid=project_id,
                iid=item_id,
                fid=field_id,
                vid=iter_id,
            )
            print(f"  Issue #{issue_num} -> {sprint_full}")
        else:
            print(f"  WARN: No sprint id found for '{sprint_full}'", file=sys.stderr)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--repo",
        required=True,
        help="Repository in owner/name format, e.g. woodbase/Xeno-breach",
    )
    parser.add_argument(
        "--skip-project",
        action="store_true",
        help="Skip GitHub Project and iteration creation",
    )
    args = parser.parse_args()

    repo = args.repo
    owner = repo.split("/")[0]

    print(f"Repository : {repo}")
    print(f"Owner      : {owner}")

    create_labels(repo)
    milestone_map = create_milestones(repo)
    issue_sprint_pairs = create_issues(repo, milestone_map)

    if not args.skip_project:
        project_id, _ = create_project(owner)
        field_id = add_iteration_field(project_id)
        sprint_id_map = configure_iterations(project_id, field_id)
        add_issues_to_project(repo, project_id, field_id, sprint_id_map, issue_sprint_pairs)

    print("\n\u2705 Done! All milestones, labels, issues and project sprints have been created.")


if __name__ == "__main__":
    main()
