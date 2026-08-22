#include <signal.h>

// According to the wikipedia, the C standard defines only 6 signals:
// SIGABRT - "abort", abnormal termination.
// SIGFPE - floating point exception.
// SIGILL - "illegal", invalid instruction.
// SIGINT - "interrupt", interactive attention request sent to the program.
// SIGSEGV - "segmentation violation", invalid memory access.
// SIGTERM - "terminate", termination request sent to the program.

typedef void (*SG_SignalHandlerFunction)(void* data);

struct SG_SignalHandler {
    int signal;
    SG_SignalHandlerFunction function;
    void* data;
};

SG_SignalHandler SG_SignalHandlers[32] = {};

#ifndef _WIN32
static struct sigaction SG_PrevActions[32];
static bool SG_PrevActionSaved[32] = {};

void SG_SignalReceiver(int sig, siginfo_t* info, void* ucontext) {
    if (sig < 32) {
        SG_SignalHandlers[sig].function(SG_SignalHandlers[sig].data);

        struct sigaction* prevAction = &SG_PrevActions[sig];
        if (prevAction->sa_flags & SA_SIGINFO && prevAction->sa_sigaction) {
            prevAction->sa_sigaction(sig, info, ucontext);
        } else if (prevAction->sa_handler == SIG_DFL) {
            signal(sig, SIG_DFL);
            raise(sig);
        } else if (prevAction->sa_handler != SIG_IGN && prevAction->sa_handler != NULL) {
            prevAction->sa_handler(sig);
        }
    }
}

void SG_RegisterHandler(int sig, SG_SignalHandlerFunction function, void* data) {
    SG_SignalHandlers[sig] = {sig, function, data};
    struct sigaction sa;
    sa.sa_sigaction = SG_SignalReceiver;
    sa.sa_flags = SA_SIGINFO | SA_ONSTACK;
    sigemptyset(&sa.sa_mask);

    if (!SG_PrevActionSaved[sig]) {
        sigaction(sig, &sa, &SG_PrevActions[sig]);
        SG_PrevActionSaved[sig] = true;
    } else {
        sigaction(sig, &sa, NULL);  // already installed once — don't re-capture ourselves as "previous"
    }
}

#else
#include <windows.h>

void SG_SignalReceiver(int sig) {
    if (sig < 32) {
        SG_SignalHandlers[sig].function(SG_SignalHandlers[sig].data);
    }
}

BOOL WINAPI WindowsCtrlHandler(DWORD dwCtrlType) {
    if (dwCtrlType == CTRL_C_EVENT || dwCtrlType == CTRL_BREAK_EVENT) {
        // Find SIGINT handler
        if (SG_SignalHandlers[SIGINT].function) {
            SG_SignalHandlers[SIGINT].function(SG_SignalHandlers[SIGINT].data);
        }
        return TRUE;  // Signal handled
    }
    return FALSE;
}

void SG_RegisterHandler(int sig, SG_SignalHandlerFunction function, void* data) {
    SG_SignalHandlers[sig] = {sig, function, data};

    if (sig == SIGINT) {
        SetConsoleCtrlHandler(WindowsCtrlHandler, TRUE);
    } else {
        signal(sig, SG_SignalReceiver);
    }
}

#endif

