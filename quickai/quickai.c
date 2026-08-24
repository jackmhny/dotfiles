#define _POSIX_C_SOURCE 200809L

#include <errno.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

static void fail(const char *what)
{
	perror(what);
	exit(1);
}

static void path(char out[PATH_MAX], const char *a, const char *b)
{
	if (snprintf(out, PATH_MAX, "%s/%s", a, b) >= PATH_MAX) {
		errno = ENAMETOOLONG;
		fail("quickai");
	}
}

static void makedir(const char *dir)
{
	if (mkdir(dir, 0700) == -1 && errno != EEXIST)
		fail(dir);
}

static void linkfile(const char *from, const char *to)
{
	if (symlink(from, to) == -1 && errno != EEXIST)
		fail(to);
}

int main(void)
{
	const char *home = getenv("HOME");
	const char *runtime = getenv("XDG_RUNTIME_DIR");
	const char *config = getenv("XDG_CONFIG_HOME");
	char runtime_fallback[PATH_MAX], config_fallback[PATH_MAX];
	char dir[PATH_MAX], from[PATH_MAX], to[PATH_MAX], codex[PATH_MAX];
	char *slash;
	ssize_t n;

	if (!home || !*home) {
		fprintf(stderr, "quickai: HOME is not set\n");
		return 1;
	}
	if (!runtime || !*runtime) {
		path(runtime_fallback, home, ".cache");
		makedir(runtime_fallback);
		runtime = runtime_fallback;
	}
	if (!config || !*config) {
		path(config_fallback, home, ".config");
		config = config_fallback;
	}

	path(dir, runtime, "quickai");
	makedir(dir);

	path(from, config, "quickai/config.toml");
	path(to, dir, "config.toml");
	linkfile(from, to);
	path(to, dir, "quickai.config.toml");
	linkfile(from, to);
	path(from, home, ".codex/auth.json");
	path(to, dir, "auth.json");
	linkfile(from, to);
	path(from, home, ".codex/models_cache.json");
	path(to, dir, "models_cache.json");
	linkfile(from, to);

	if (setenv("CODEX_HOME", dir, 1) == -1)
		fail("setenv");
	if (chdir(home) == -1)
		fail(home);
	path(from, home, ".local/bin/codex");
	n = readlink(from, codex, sizeof(codex) - 1);
	if (n < 1 || n >= (ssize_t)sizeof(codex) - 1)
		fail(from);
	codex[n] = '\0';
	if (codex[0] != '/' || access(codex, X_OK) == -1)
		fail(from);
	if (!(slash = strrchr(codex, '/')))
		fail(codex);
	*slash = '\0';
	if (snprintf(to, PATH_MAX, "%s:/usr/local/bin:/usr/bin:/bin", codex) >= PATH_MAX)
		fail("PATH");
	if (setenv("PATH", to, 1) == -1)
		fail("PATH");
	*slash = '/';

	execl("/usr/bin/xterm", "xterm",
	       "-class", "QuickAI", "-name", "quickai",
	       "-title", "ai: luna / medium / yolo",
	       "-fa", "JetBrainsMono Nerd Font", "-fs", "11",
	       "-bg", "#0d1117", "-fg", "#d8dee9", "-cr", "#88c0d0",
	       "-b", "12", "-geometry", "100x30",
	       "-e", codex,
	       "-p", "quickai",
	       "-m", "gpt-5.6-luna",
	       "-c", "model_reasoning_effort=\"medium\"",
	       "-c", "service_tier=\"default\"",
	       "-c", "features.fast_mode=false",
	       "--dangerously-bypass-approvals-and-sandbox",
	       "--no-alt-screen", (char *)NULL);
	fail("xterm");
}
