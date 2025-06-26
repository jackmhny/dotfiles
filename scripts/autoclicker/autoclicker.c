#include <X11/Xlib.h>
#include <X11/extensions/XTest.h>
#include <unistd.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <sys/stat.h>

#define PIDFILE "/tmp/autoclicker.pid"
#define CPS 12

volatile sig_atomic_t running = 1;

void cleanup(Display *dpy) {
    // Notify that we're stopping
    system("notify-send 'Autoclicker' 'Stopped'");
    remove(PIDFILE);
    if (dpy)
        XCloseDisplay(dpy);
}

void handle_signal(int sig) {
    running = 0;
}

int file_exists(const char *filename) {
    struct stat buf;
    return (stat(filename, &buf) == 0);
}

int main(void) {
    FILE *fp;
    pid_t pid;

    /* ----- Toggle: If PID file exists check if autoclicker is running ----- */
    if (file_exists(PIDFILE)) {
        fp = fopen(PIDFILE, "r");
        if (fp) {
            if (fscanf(fp, "%d", &pid) == 1) {
                fclose(fp);
                // Check if process is alive
                if (kill(pid, 0) == 0) {
                    // Process is running; request it to terminate.
                    if (kill(pid, SIGTERM) == 0) {
                        printf("Autoclicker (PID %d) signaled to stop.\n", pid);
                        system("notify-send 'Autoclicker' 'Stopped'");
                    } else {
                        perror("Failed to signal running autoclicker");
                    }
                    // Remove PID file and exit.
                    remove(PIDFILE);
                    return 0;
                } else {
                    // Process not found; stale file.
                    printf("Found stale PID file. Removing.\n");
                    remove(PIDFILE);
                }
            } else {
                fclose(fp);
                fprintf(stderr, "Failed to read PID from %s\n", PIDFILE);
                remove(PIDFILE);
            }
        }
    }

    /* ----- Write our PID into the PID file ----- */
    fp = fopen(PIDFILE, "w");
    if (!fp) {
        perror("Unable to create PID file");
        return 1;
    }
    fprintf(fp, "%d", getpid());
    fclose(fp);

    /* ----- Setup signal handlers for graceful termination ----- */
    signal(SIGTERM, handle_signal);
    signal(SIGINT, handle_signal);

    /* ----- Open Display ----- */
    Display *dpy = XOpenDisplay(NULL);
    if (dpy == NULL) {
        fprintf(stderr, "Cannot open display\n");
        remove(PIDFILE);
        return 1;
    }

    // Calculate sleep interval in microseconds.
    unsigned int sleep_usecs = 1000000 / CPS;

    // Notify that the autoclicker has started.
    {
        char start_cmd[128];
        snprintf(start_cmd, sizeof(start_cmd),
                 "notify-send 'Autoclicker' 'Started at %d clicks per second (PID: %d)'",
                 CPS, getpid());
        system(start_cmd);
    }
    printf("Autoclicker started at %d clicks per second (PID: %d).\n", CPS, getpid());

    /* ----- Main Clicking Loop ----- */
    while (running) {
        // Simulate button press and release for left mouse (button 1)
        if (!XTestFakeButtonEvent(dpy, 1, True, CurrentTime) ||
            !XTestFakeButtonEvent(dpy, 1, False, CurrentTime)) {
            fprintf(stderr, "Failed to simulate click event. Exiting...\n");
            break;
        }
        XFlush(dpy);
        usleep(sleep_usecs);
    }

    printf("Autoclicker stopping...\n");
    cleanup(dpy);
    return 0;
}
