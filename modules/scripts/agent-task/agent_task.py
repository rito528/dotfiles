import argparse
import fcntl
import os
import re
import sqlite3
import subprocess
import sys
from contextlib import ExitStack, contextmanager
from pathlib import Path

ARTIFACTS = Path(".work/agent-tasks")


class TaskError(Exception):
    pass


def git(directory, *args):
    result = subprocess.run(
        ["git", "-C", directory, *args], stdout=subprocess.PIPE, stderr=subprocess.PIPE
    )
    if result.returncode:
        raise TaskError(os.fsdecode(result.stderr).strip() or f"git {args[0]} failed")
    return os.fsdecode(result.stdout).rstrip("\n")


def worktrees(directory):
    output = git(directory, "worktree", "list", "--porcelain", "-z")
    return [
        tuple(field.partition(" ")[::2] for field in record.split("\0") if field)
        for record in output.split("\0\0")
        if record
    ]


def checkout_ref(directory):
    ref = git(directory, "rev-parse", "--symbolic-full-name", "HEAD")
    # Record the exact commit when HEAD is detached.
    return git(directory, "rev-parse", "HEAD") if ref == "HEAD" else ref


class Repository:
    def __init__(self):
        self.checkout = Path(git(".", "rev-parse", "--show-toplevel")).resolve()
        self.common = Path(git(self.checkout, "rev-parse", "--path-format=absolute", "--git-common-dir"))
        primary = dict(worktrees(self.checkout)[0])
        if "bare" in primary:
            raise TaskError("a repository with a primary checkout is required")
        self.primary = Path(primary["worktree"]).resolve()

    @contextmanager
    def transaction(self):
        db = sqlite3.connect(self.common / "agent-tasks.sqlite", timeout=30)
        db.row_factory = sqlite3.Row
        try:
            with db:
                db.execute("BEGIN IMMEDIATE")
                db.execute(
                    """CREATE TABLE IF NOT EXISTS tasks (
                        name TEXT PRIMARY KEY, checkout TEXT NOT NULL,
                        ref TEXT NOT NULL, isolated INTEGER NOT NULL, closed INTEGER NOT NULL
                    )"""
                )
                yield db
        finally:
            db.close()

    @contextmanager
    def task_lock(self, name):
        lock_dir = self.common / "agent-task-locks"
        lock_dir.mkdir(exist_ok=True)
        with (lock_dir / name).open("a") as lock:
            try:
                fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError:
                raise TaskError(f"task is already in use: {name}") from None
            yield lock

    def in_use(self, name):
        try:
            with (self.common / "agent-task-locks" / name).open() as lock:
                fcntl.flock(lock, fcntl.LOCK_SH | fcntl.LOCK_NB)
        except BlockingIOError:
            return True
        except FileNotFoundError:
            return False
        return False

    def artifacts(self, name):
        return self.primary / ARTIFACTS / name

    def prepare_artifacts(self, name):
        root = self.primary / ARTIFACTS
        if root.resolve() != root:
            raise TaskError(f"artifact directory traverses a symlink: {root}")
        path = self.artifacts(name)
        if path.resolve() != path:
            raise TaskError(f"artifact directory traverses a symlink: {path}")
        if git(self.primary, "ls-files", "--", ARTIFACTS.as_posix()):
            raise TaskError(f"artifact directory contains tracked files: {root}")
        exclude = self.common / "info/exclude"
        rule = f"/{ARTIFACTS.as_posix()}/"
        existing = exclude.read_text(errors="surrogateescape") if exclude.exists() else ""
        if rule not in existing.splitlines():
            exclude.parent.mkdir(parents=True, exist_ok=True)
            with exclude.open("a") as stream:
                stream.write(("" if not existing or existing.endswith("\n") else "\n") + rule + "\n")
        git(self.primary, "check-ignore", "--quiet", "--", str(path))
        path.mkdir(parents=True, exist_ok=True)

    def verify_checkout(self, path, ref):
        if not path.is_dir() or path.resolve() != path:
            raise TaskError(f"registered checkout is missing or moved: {path}")
        top_level = Path(git(path, "rev-parse", "--show-toplevel")).resolve()
        common = Path(git(path, "rev-parse", "--path-format=absolute", "--git-common-dir"))
        if top_level != path or common.resolve() != self.common.resolve() or checkout_ref(path) != ref:
            raise TaskError(f"repository or branch changed at {path}; restore the registered checkout")

    def require_checkout(self, task):
        if task["closed"]:
            raise TaskError(f"task is closed: {task['name']}; run agent-task start")
        path = Path(task["checkout"])
        self.verify_checkout(path, task["ref"])
        return path


def lookup(db, name):
    result = db.execute("SELECT * FROM tasks WHERE name = ?", (name,)).fetchone()
    if result is None:
        raise TaskError(f"unknown task: {name}")
    return result


def start(repo, db, name, isolated):
    existing = db.execute("SELECT * FROM tasks WHERE name = ?", (name,)).fetchone()
    if existing is not None and not existing["closed"]:
        if isolated and not existing["isolated"]:
            raise TaskError("task already uses a shared checkout; close it before changing isolation")
        path = repo.require_checkout(existing)
        repo.prepare_artifacts(name)
        return path, None

    isolated = isolated or bool(existing and existing["isolated"])
    warning = None
    if isolated:
        path = repo.primary.parent / f"{repo.primary.name}.worktrees" / name
        if path.resolve() != path or path.exists():
            raise TaskError(f"worktree path is already occupied: {path}")
        branch = f"agent-task/{name}"
        ref = f"refs/heads/{branch}"
        if existing is not None and existing["isolated"]:
            git(repo.checkout, "show-ref", "--verify", "--quiet", ref)
            tags = git(repo.checkout, "tag", "--list", branch)
            if tags:
                raise TaskError(f"tag conflicts with the task branch: {branch}")
            arguments = ("--", path, branch)
        else:
            arguments = ("-b", branch, "--", path, "HEAD")
        repo.prepare_artifacts(name)
        try:
            git(repo.checkout, "worktree", "add", *arguments)
        except TaskError as error:
            try:
                repo.verify_checkout(path, ref)
            except TaskError:
                raise error
            warning = f"{error}\nworktree was created and registered at {path}"
        else:
            repo.verify_checkout(path, ref)
    else:
        path = repo.checkout
        ref = checkout_ref(path)
        current = db.execute(
            "SELECT name FROM tasks WHERE checkout = ? AND closed = 0", (str(path),)
        ).fetchone()
        if current is not None:
            raise TaskError(f"checkout already belongs to {current['name']}; use --worktree for parallel work")
        repo.prepare_artifacts(name)
    db.execute(
        """INSERT OR REPLACE INTO tasks (name, checkout, ref, isolated, closed)
        VALUES (?, ?, ?, ?, 0)""",
        (name, str(path), ref, int(isolated)),
    )
    return path, warning


def close(repo, db, name):
    task = lookup(db, name)
    if task["closed"]:
        return
    if task["isolated"]:
        path = repo.require_checkout(task)
        if Path.cwd().is_relative_to(path):
            raise TaskError("close the worktree from another checkout")
        git_dir = Path(git(path, "rev-parse", "--absolute-git-dir"))
        operations = (
            "MERGE_HEAD", "CHERRY_PICK_HEAD", "REVERT_HEAD", "BISECT_START",
            "rebase-apply", "rebase-merge", "sequencer",
        )
        if any((git_dir / operation).exists() for operation in operations):
            raise TaskError(f"finish the Git operation before closing the worktree: {path}")
        index_entries = git(path, "ls-files", "-v", "-z").split("\0")
        if any(entry and (entry[0].islower() or entry[0] == "S") for entry in index_entries):
            raise TaskError(f"worktree contains files hidden from git status: {path}")
        status = git(
            path, "status", "--porcelain=v1", "-z", "--untracked-files=all",
            "--ignored=matching", "--ignore-submodules=none",
        )
        if status:
            raise TaskError(f"worktree contains local changes or untracked/ignored files: {path}")
        git(repo.primary, "worktree", "remove", "--", path)
    db.execute("UPDATE tasks SET closed = 1 WHERE name = ?", (name,))


def list_tasks(repo, db):
    for task in db.execute("SELECT * FROM tasks ORDER BY name"):
        if task["closed"]:
            state = "closed"
        else:
            try:
                path = repo.require_checkout(task)
                state = "dirty" if git(path, "status", "--porcelain=v1") else "ready"
                if repo.in_use(task["name"]):
                    state = f"running/{state}"
            except TaskError:
                state = "unavailable"
        ref = task["ref"].removeprefix("refs/heads/")
        print(f"{task['name']}\t{state}\t{ref}\t{task['checkout']}\t{repo.artifacts(task['name'])}")


def task_name(value):
    if not re.fullmatch(r"[a-z0-9][a-z0-9-]{0,62}", value):
        raise argparse.ArgumentTypeError("use 1–63 lowercase letters, digits or hyphens")
    return value


def parse_args():
    parser = argparse.ArgumentParser(
        prog="agent-task", description="Manage named AI agent workspaces in a Git repository"
    )
    commands = parser.add_subparsers(dest="action", required=True)
    commands.add_parser("list", help="list registered tasks and checkouts")
    for action in ("start", "path", "artifacts", "open", "run", "close"):
        command = commands.add_parser(action)
        command.add_argument("name", type=task_name)
        if action == "start":
            command.add_argument("--worktree", action="store_true", help="use a dedicated Git worktree")
        if action == "run":
            command.add_argument("command", nargs=argparse.REMAINDER)
    return parser.parse_args()


def main():
    args = parse_args()
    try:
        repo = Repository()
        with ExitStack() as stack:
            with repo.transaction() as db:
                if args.action == "list":
                    list_tasks(repo, db)
                    return 0
                if args.action == "start":
                    path, warning = start(repo, db, args.name, args.worktree)
                    if warning:
                        print(f"agent-task: {warning}", file=sys.stderr)
                        return 1
                    print(path)
                    return 0
                if args.action == "close":
                    with repo.task_lock(args.name):
                        close(repo, db, args.name)
                    return 0

                task = lookup(db, args.name)
                if args.action == "artifacts":
                    print(repo.artifacts(args.name))
                    return 0
                path = repo.require_checkout(task)
                if args.action == "run":
                    lock = stack.enter_context(repo.task_lock(args.name))

            if args.action == "path":
                print(path)
            elif args.action == "open":
                return subprocess.call(["code", "--new-window", path], cwd=path)
            else:
                command = args.command
                if command and command[0] == "--":
                    command = command[1:]
                if not command:
                    raise TaskError("specify a command after the task name")
                env = os.environ | {
                    "AGENT_TASK_NAME": args.name,
                    "AGENT_TASK_ROOT": str(path),
                    "AGENT_TASK_ARTIFACTS": str(repo.artifacts(args.name)),
                }
                return subprocess.call(command, cwd=path, env=env, pass_fds=(lock.fileno(),))
        return 0
    except (TaskError, OSError, sqlite3.Error) as error:
        print(f"agent-task: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
