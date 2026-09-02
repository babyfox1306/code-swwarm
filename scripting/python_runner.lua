-- Compatibility entry point.
-- The previous V0.2 implementation in this path had a broken JSON serializer
-- and unsafe shared/stale IPC lifecycle. Keep one source of truth only.
return require("scripting.python_runner_v03")
