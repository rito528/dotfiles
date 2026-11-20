import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

CLI = Path(__file__).resolve().parents[2] / "modules/scripts/agent-task/agent_task.py"


class AgentTaskTest(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.directory = Path(temporary.name).resolve()
        self.repo = self.directory / "repo with spaces"
        self.repo.mkdir()
        self.git("init", "--initial-branch=main")
        self.git("config", "user.name", "Test User")
        self.git("config", "user.email", "agent-task@example.com")
        (self.repo / "tracked").write_text("base\n")
        self.git("add", "tracked")
        self.git("commit", "--no-gpg-sign", "-m", "initial")

    def git(self, *args, cwd=None):
        return subprocess.check_output(["git", *args], cwd=cwd or self.repo, text=True)

    def command(self, *args, cwd=None, env=None):
        return subprocess.run(
            [sys.executable, "-B", CLI, *args],
            cwd=cwd or self.repo, env=env, capture_output=True, text=True,
        )

    def task(self, *args, **kwargs):
        result = self.command(*args, **kwargs)
        self.assertEqual(result.returncode, 0, result.stderr)
        return result.stdout.strip()

    def test_reuses_isolated_worktree_and_passes_same_path_to_the_agent_and_editor(self):
        alpha = Path(self.task("start", "alpha", "--worktree"))
        beta = Path(self.task("start", "beta", "--worktree"))
        self.assertNotEqual(alpha, beta)
        self.assertEqual(self.task("start", "alpha", cwd=beta), str(alpha))
        self.assertEqual(self.git("worktree", "list", "--porcelain").count("worktree "), 3)
        artifacts = self.repo / ".work/agent-tasks/alpha"
        self.assertEqual(self.task("artifacts", "alpha", cwd=beta), str(artifacts))
        self.git("check-ignore", str(artifacts / "review.txt"))
        self.assertIn("alpha\tready\tagent-task/alpha", self.task("list", cwd=beta))
        probe = "import json, os; print(json.dumps([os.getcwd(), os.environ['AGENT_TASK_ARTIFACTS']]))"
        output = self.task("run", "alpha", "--", sys.executable, "-c", probe, cwd=beta)
        self.assertEqual(json.loads(output), [str(alpha), str(artifacts)])

        code = self.directory / "code"
        code.write_text('#!/bin/sh\nprintf "%s\\n" "$PWD" "$@"\n')
        code.chmod(0o755)
        env = os.environ | {"PATH": f"{self.directory}{os.pathsep}{os.environ['PATH']}"}
        self.assertEqual(
            self.task("open", "alpha", cwd=beta, env=env).splitlines(),
            [str(alpha), "--new-window", str(alpha)],
        )

    def test_close_keeps_branch_and_artifacts_and_refuses_hidden_changes(self):
        alpha = Path(self.task("start", "alpha", "--worktree"))
        artifact = Path(self.task("artifacts", "alpha")) / "summary.txt"
        artifact.write_text("keep\n")
        local = alpha / ".work/agent-tasks/local-generated"
        local.parent.mkdir(parents=True)
        local.write_text("ignored in Git\n")
        self.assertNotEqual(self.command("close", "alpha").returncode, 0)
        self.assertTrue(local.is_file())
        local.unlink()
        local.parent.rmdir()
        local.parent.parent.rmdir()
        self.git("update-index", "--assume-unchanged", "tracked", cwd=alpha)
        self.assertNotEqual(self.command("close", "alpha").returncode, 0)
        self.git("update-index", "--no-assume-unchanged", "tracked", cwd=alpha)
        self.task("close", "alpha")
        self.assertFalse(alpha.exists())
        self.assertEqual(artifact.read_text(), "keep\n")
        self.assertIn("agent-task/alpha", self.git("branch", "--list"))
        self.assertEqual(self.task("start", "alpha"), str(alpha))

    def test_running_task_cannot_be_closed_or_started_twice(self):
        self.task("start", "alpha", "--worktree")
        command = [
            sys.executable, "-B", CLI, "run", "alpha", "--", sys.executable, "-c",
            'import sys; print("running", flush=True); sys.stdin.readline()',
        ]
        with subprocess.Popen(
            command, cwd=self.repo, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
        ) as running:
            try:
                self.assertEqual(running.stdout.readline().strip(), b"running")
                self.assertIn("alpha\trunning/ready", self.task("list"))
                self.assertIn("already in use", self.command("close", "alpha").stderr)
                duplicate = self.command("run", "alpha", "--", sys.executable, "--version")
                self.assertIn("already in use", duplicate.stderr)
            finally:
                running.communicate(b"finish\n", timeout=10)
        self.task("close", "alpha")

    def test_does_not_adopt_an_unmanaged_branch_or_changed_checkout(self):
        self.git("branch", "agent-task/unmanaged")
        self.assertNotEqual(self.command("start", "unmanaged", "--worktree").returncode, 0)
        self.assertNotIn("unmanaged", self.task("list"))

        self.task("start", "local")
        self.assertNotEqual(self.command("start", "local", "--worktree").returncode, 0)
        self.assertNotEqual(self.command("start", "another").returncode, 0)
        self.git("switch", "-c", "elsewhere")
        self.assertNotEqual(self.command("path", "local").returncode, 0)
        self.assertIn("local\tunavailable", self.task("list"))

    def test_failing_git_hook_leaves_a_registered_checkout(self):
        hook = self.repo / ".git/hooks/post-checkout"
        hook.write_text("#!/bin/sh\necho hook-failed >&2\nexit 1\n")
        hook.chmod(0o755)
        result = self.command("start", "alpha", "--worktree")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("hook-failed", result.stderr)
        self.assertEqual(self.task("start", "alpha"), self.task("path", "alpha"))

    def test_reopen_does_not_use_a_tag_in_place_of_a_deleted_branch(self):
        self.task("start", "alpha", "--worktree")
        self.task("close", "alpha")
        self.git("branch", "-D", "agent-task/alpha")
        self.git("update-ref", "refs/tags/agent-task/alpha", "HEAD")
        self.assertNotEqual(self.command("start", "alpha").returncode, 0)
        self.assertEqual(self.git("worktree", "list", "--porcelain").count("worktree "), 1)
        self.assertIn("alpha\tclosed", self.task("list"))

    def test_close_refuses_an_in_progress_operation_even_with_no_file_changes(self):
        alpha = Path(self.task("start", "alpha", "--worktree"))
        (alpha / "tracked").write_text("change\n")
        self.git("add", "tracked", cwd=alpha)
        self.git("commit", "--no-gpg-sign", "-m", "change", cwd=alpha)
        git_dir = Path(self.git("rev-parse", "--absolute-git-dir", cwd=alpha).strip())
        self.assertEqual(self.git("status", "--porcelain", cwd=alpha), "")
        subprocess.run(["git", "cherry-pick", "HEAD"], cwd=alpha, capture_output=True)
        self.assertTrue((git_dir / "CHERRY_PICK_HEAD").is_file())
        self.assertIn("finish the Git operation", self.command("close", "alpha").stderr)
        self.assertTrue((git_dir / "CHERRY_PICK_HEAD").is_file())

    def test_goal_persists_on_reopen_and_can_seed_native_codex_goal(self):
        self.task("start", "alpha", "--worktree")
        objective = "Add an endpoint.\nVerify the  old client."
        self.task("goal", "alpha", "--set", objective)
        self.assertEqual(self.task("goal", "alpha"), objective)
        self.assertEqual(
            self.task("goal", "alpha", "--codex-command"),
            "/goal Add an endpoint. Verify the  old client.",
        )
        self.assertNotEqual(self.command("goal", "alpha", "--set", "").returncode, 0)
        self.task("close", "alpha")
        self.task("start", "alpha")
        probe = "import os; print(os.environ['AGENT_TASK_GOAL'])"
        self.assertEqual(self.task("run", "alpha", "--", sys.executable, "-c", probe), objective)
        self.task("goal", "alpha", "--clear")
        self.assertNotEqual(self.command("goal", "alpha").returncode, 0)
        self.assertEqual(self.task("run", "alpha", "--", sys.executable, "-c", probe), "")

    def test_concurrent_start_creates_one_checkout(self):
        command = [sys.executable, "-B", CLI, "start", "parallel", "--worktree"]
        with subprocess.Popen(command, cwd=self.repo, stdout=subprocess.PIPE, stderr=subprocess.PIPE) as first:
            second = self.command("start", "parallel", "--worktree")
            first_output, first_error = first.communicate(timeout=10)
            self.assertEqual(first.returncode, 0, first_error)
        self.assertEqual(second.returncode, 0, second.stderr)
        self.assertEqual(os.fsdecode(first_output), second.stdout)
        self.assertEqual(self.git("worktree", "list", "--porcelain").count("worktree "), 2)
