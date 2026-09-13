/* Steam's lsof -F up -i TCP@<endpoint> subset, using socket metadata only.
 * Reports actual kernel PID/UID/FD values. Does not omit Docker or inspect
 * vnode/file paths. Unsupported addresses fail closed instead of fabricating
 * an owner. This is a local compatibility helper, not a Valve component.
 */
#include <libproc.h>
#include <sys/proc_info.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

static double clock_seconds(void) {
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return t.tv_sec + t.tv_nsec / 1e9;
}

int main(int argc, char **argv) {
    if (argc != 2) return 2;
    char host[INET6_ADDRSTRLEN];
    const char *split = strrchr(argv[1], ':');
    if (!split || split == argv[1]) return 2;
    size_t length = split - argv[1];
    const char *begin = argv[1];
    if (*begin == '[' && split[-1] == ']') { begin++; length -= 2; }
    if (length >= sizeof(host)) return 2;
    memcpy(host, begin, length); host[length] = 0;
    char *end;
    long port = strtol(split + 1, &end, 10);
    if (end == split + 1 || *end || port < 1 || port > 65535) return 2;
    struct in_addr ipv4;
    struct in6_addr ipv6;
    int family;
    if (inet_pton(AF_INET, host, &ipv4) == 1 &&
        (ntohl(ipv4.s_addr) >> 24) == 127) family = AF_INET;
    else if (inet_pton(AF_INET6, host, &ipv6) == 1 &&
             IN6_IS_ADDR_LOOPBACK(&ipv6)) family = AF_INET6;
    else return 2;

    double started = clock_seconds();
    int cap = proc_listallpids(NULL, 0) + 4096;
    if (cap <= 4096) return 2;
    int *ids = calloc(cap, sizeof(*ids));
    if (!ids) return 2;
    int n = proc_listallpids(ids, cap * sizeof(*ids));
    if (n <= 0 || n >= cap) { free(ids); return 2; }
    int matches = 0;
    for (int i = 0; i < n; i++) {
        int pid = ids[i];
        if (pid <= 0) continue;
        struct proc_bsdinfo bi;
        if (proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &bi, sizeof(bi)) != sizeof(bi)) continue;
        int size = proc_pidinfo(pid, PROC_PIDLISTFDS, 0, NULL, 0);
        if (size <= 0 || size > 64 * 1024 * 1024) continue;
        size += 4096 * sizeof(struct proc_fdinfo);
        struct proc_fdinfo *fds = malloc(size);
        if (!fds) { free(ids); return 2; }
        int used = proc_pidinfo(pid, PROC_PIDLISTFDS, 0, fds, size);
        if (used >= size) { free(fds); free(ids); return 2; }
        int printed_pid = 0;
        for (int j = 0; j < used / (int)sizeof(*fds); j++) {
            if (fds[j].proc_fdtype != PROX_FDTYPE_SOCKET) continue;
            struct socket_fdinfo info;
            if (proc_pidfdinfo(pid, fds[j].proc_fd, PROC_PIDFDSOCKETINFO,
                              &info, sizeof(info)) != sizeof(info)) continue;
            if (info.psi.soi_kind != SOCKINFO_TCP) continue;
            const struct in_sockinfo *in = &info.psi.soi_proto.pri_tcp.tcpsi_ini;
            int local = 0, remote = 0;
            if (family == AF_INET && (in->insi_vflag & INI_IPV4)) {
                local = in->insi_laddr.ina_46.i46a_addr4.s_addr == ipv4.s_addr;
                remote = in->insi_faddr.ina_46.i46a_addr4.s_addr == ipv4.s_addr;
            } else if (family == AF_INET6 && (in->insi_vflag & INI_IPV6)) {
                local = memcmp(&in->insi_laddr.ina_6, &ipv6, sizeof(ipv6)) == 0;
                remote = memcmp(&in->insi_faddr.ina_6, &ipv6, sizeof(ipv6)) == 0;
            }
            local = local && ntohs(in->insi_lport) == port;
            remote = remote && ntohs(in->insi_fport) == port;
            if (!local && !remote) continue;
            if (!printed_pid) { printf("p%d\nu%u\n", pid, bi.pbi_uid); printed_pid = 1; }
            printf("f%d\n", fds[j].proc_fd);
            matches++;
        }
        free(fds);
    }
    free(ids);
    const char *home_dir = getenv("HOME");
    if (home_dir) {
        char path[1024];
        int size = snprintf(path, sizeof(path), "%s/.steam-socket-compat/lookups.log", home_dir);
        if (size > 0 && (size_t)size < sizeof(path)) {
            FILE *log = fopen(path, "a");
            if (log) {
                fprintf(log, "time=%ld endpoint=%s matches=%d seconds=%.3f\n",
                        (long)time(NULL), argv[1], matches, clock_seconds() - started);
                fclose(log);
            }
        }
    }
    return matches ? 0 : 1;
}
