/* Collect stack-trace profiles of running program(s).
   Copyright (C) 2025-2026 Red Hat, Inc.
   This file is part of elfutils.

   This file is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 3 of the License, or
   (at your option) any later version.

   elfutils is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.  */

#ifdef HAVE_CONFIG_H
# include <config.h>
#endif

#include "printversion.h"

#include <string>
#include <memory>
#include <iomanip>
#include <map>
#include <unordered_map>
#include <vector>
#include <bitset>
#include <stdexcept>
#include <cstring>
#include <csignal>
#include <cassert>
#include <chrono>
#include <iostream>
#include <fstream>
#include <sstream>
#include <cinttypes>
#include <format>
#include <filesystem>

#include <sys/utsname.h>

#include <sys/syscall.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <sys/wait.h>
#include <poll.h>
#ifdef HAVE_LINUX_PERF_EVENT_H
#include <linux/perf_event.h>
#endif
#include <argp.h>
#include <fcntl.h>
#include <dirent.h>

#include <system.h>

#ifdef HAVE_PERFMON_PFMLIB_PERF_EVENT_H
#include <perfmon/pfmlib_perf_event.h>
#endif

#include <json-c/json.h>

#include <gelf.h>
#include <dwarf.h>
#include <libdwfl.h>
#include <libdwfl_stacktrace.h>
#include <libdw.h>
#include "../libebl/libebl.h"

// optional debug code
//#define STACKPROF_STATS_DEBUG

using namespace std;

////////////////////////////////////////////////////////////////////////
// find_debuginfo callbacks

#ifdef FIND_DEBUGINFO

static char *debuginfo_path = NULL;

static const Dwfl_Callbacks dwfl_cfi_callbacks =
{
  .find_elf = dwflst_tracker_linux_proc_find_elf,
  .find_debuginfo = dwfl_standard_find_debuginfo,
  .debuginfo_path = &debuginfo_path,
};

#else

int
nop_find_debuginfo (Dwfl_Module *mod __attribute__((unused)),
		    void **userdata __attribute__((unused)),
		    const char *modname __attribute__((unused)),
		    GElf_Addr base __attribute__((unused)),
		    const char *file_name __attribute__((unused)),
		    const char *debuglink_file __attribute__((unused)),
		    GElf_Word debuglink_crc __attribute__((unused)),
		    char **debuginfo_file_name __attribute__((unused)))
{
#ifdef DEBUG_MODULES
  cerr << format("nop_find_debuginfo: modname={} file_name={} debuglink_file={}\n", modname, file_name, debuglink_file);
#endif
  return -1;
}

static const Dwfl_Callbacks dwfl_cfi_callbacks =
{
  .find_elf = dwflst_tracker_linux_proc_find_elf,
  .find_debuginfo = nop_find_debuginfo, /* work with CFI only */
};

#endif /* FIND_DEBUGINFO */


////////////////////////////////////////////////////////////////////////
// class decls

// Unwind statistics for a Dwfl and associated process.
struct UnwindDwflStats {
  Dwfl *dwfl;
  string comm;
  int max_frames; /* for diagnostic purposes */
  int total_samples; /* for diagnostic purposes */
  int lost_samples; /* for diagnostic purposes */
  int shown_errors; /* for diagnostic purposes */
  Dwfl_Unwound_Source last_unwound; /* track CFI source, for diagnostic purposes */
  Dwfl_Unwound_Source worst_unwound; /* track CFI source, for diagnostic purposes */
};

struct hash_arc {
  template <class T1, class T2>
  size_t operator()(const pair<T1, T2> &p) const {
    return hash<T1>()(p.first) ^ hash<T2>()(p.second);
  }
};

// Unwind statistics for a single module identified by build-id.
struct UnwindModuleStats {
  map<uint64_t, uint32_t> histogram; /* sorted by pc */
  unordered_map<pair<uint64_t, uint64_t>, uint32_t, hash_arc> callgraph;

  void record_pc(Dwarf_Addr pc) {
    if (histogram.count(pc) == 0)
      histogram[pc]=1;
    else
      histogram[pc]++;
  }
  void record_callgraph_arc(Dwarf_Addr from, Dwarf_Addr to) {
    pair<uint64_t, uint64_t> arc(from, to);
    if (callgraph.count(arc) == 0)
      callgraph[arc]=1;
    else
      callgraph[arc]++;
  }
};

struct UnwindStatsTable
{
  unordered_map<pid_t, UnwindDwflStats> dwfl_tab;
  unordered_map<string, UnwindModuleStats> buildid_tab;
  typedef map<string, UnwindModuleStats> buildid_map_t;

  UnwindStatsTable () {}
  ~UnwindStatsTable () {}

  UnwindDwflStats *pid_find_or_create(pid_t pid);
  string pid_find_comm(pid_t pid);
  Dwfl *pid_find_dwfl(pid_t pid);
  void pid_store_dwfl(pid_t pid, Dwfl *dwfl);

  UnwindModuleStats *buildid_find(string buildid);
  UnwindModuleStats *buildid_find_or_create(string buildid, Dwfl_Module *mod);

  void print_summary() const;
};

class PerfConsumer;

// A PerfReader creates perf_events fds, monitors for events,
// and dispatches decoded forms to a PerfConsumer.
class PerfReader
{
private:
  /* Sized by number of CPUs or threads: */
  vector<int> perf_fds;
  vector<perf_event_mmap_page *> perf_headers;
  vector<pollfd> pollfds;

  PerfConsumer *consumer; // XXX: pluralize
  Ebl *default_ebl;
  uint64_t sample_regs_user;
  int sample_regs_count;
  bool enabled;
  int page_size;
  int page_count;
  int mmap_size;
  vector<uint8_t> event_wraparound_temp; // for events straddling ring buffer end

  void decode_event(const perf_event_header* ehdr);

public:
  // PerfReader(perf_event_attr* attr, int pid, PerfConsumer* consumer); // TODO attach to process hierarchy; may modify *attr
  PerfReader(perf_event_attr* attr, PerfConsumer* consumer, int pid=-1); // TODO systemwide; may modify *attr
  ~PerfReader();

  void process_some(); // run briefly, relay decoded perf_events to consumer
  uint64_t regs_mask() { return this->sample_regs_user; }
  Ebl *ebl() { return this->default_ebl; }
};

// A PerfConsumer receives both raw and decoded (fields split out into function parameters)
// perf event records from a PerfReader.  Pure interface.
class PerfConsumer
{
protected:
  PerfReader *reader; /* access sample_regs_user etc. metadata */

public:
  PerfConsumer() {}
  PerfConsumer(PerfReader *reader) : reader(reader) {}
  void set_reader(PerfReader *reader) { this->reader = reader; }

  virtual ~PerfConsumer() {}
  virtual void process(const perf_event_header* sample) {}

  virtual void process_comm(const perf_event_header* sample,
			    uint32_t pid, uint32_t tid, bool exec, const string& comm) {}
  virtual void process_exit(const perf_event_header* sample,
			    uint32_t pid, uint32_t ppid,
			    uint32_t tid, uint32_t ptid) {}
  virtual void process_fork(const perf_event_header* sample,
			    uint32_t pid, uint32_t ppid,
			    uint32_t tid, uint32_t ptid) {}
  virtual void process_sample(const perf_event_header* sample,
			      uint64_t ip,
			      uint32_t pid, uint32_t tid,
			      uint64_t time,
			      uint64_t abi,
			      uint32_t nregs, const uint64_t *regs,
			      uint64_t data_size, const uint8_t *data) {}
  virtual void process_mmap2(const perf_event_header* sample,
			     uint32_t pid, uint32_t tid,
			     uint64_t addr, uint64_t len, uint64_t pgoff,
			     uint8_t build_id_size, const uint8_t *build_id,
			     const char *filename) {}
};

// A StatsPerfConsumer collects basic stats about perf event records.
class StatsPerfConsumer: public PerfConsumer
{
  unordered_map<int,unsigned> event_type_counts;

public:
  StatsPerfConsumer() {}
  ~StatsPerfConsumer(); // report to clog
  void process_comm(const perf_event_header* sample,
		    uint32_t pid, uint32_t tid, bool exec, const string& comm);
  void process_exit(const perf_event_header* sample,
		    uint32_t pid, uint32_t ppid,
		    uint32_t tid, uint32_t ptid);
  void process_fork(const perf_event_header* sample,
		    uint32_t pid, uint32_t ppid,
		    uint32_t tid, uint32_t ptid);
  void process_sample(const perf_event_header* sample,
		      uint64_t ip,
		      uint32_t pid, uint32_t tid,
		      uint64_t time,
		      uint64_t abi,
		      uint32_t nregs, const uint64_t *regs,
		      uint64_t data_size, const uint8_t *data);
  void process_mmap2(const perf_event_header* sample,
		     uint32_t pid, uint32_t tid,
		     uint64_t addr, uint64_t len, uint64_t pgoff,
		     uint8_t build_id_size, const uint8_t *build_id,
		     const char *filename);
  void process(const perf_event_header* sample);
};

// An UnwindSample records an unwound call stack from a perf sample.
struct UnwindSample
{
  const perf_event_header *event;
  Dwfl *dwfl;
  uint32_t pid, tid;
  vector<Dwarf_Addr> addrs;
  int elfclass;

  Dwarf_Addr base; /* for diagnostic purposes */
  Dwarf_Addr sp; /* for diagnostic purposes */
};

class UnwindSampleConsumer;

// A PerfConsumerUnwinder accepts decoded perf events, and relays
// UnwindSample objects to an UnwindSampleConsumer.
class PerfConsumerUnwinder: public PerfConsumer
{
  UnwindSampleConsumer *consumer;
  UnwindSample last_us; // XXX: why & is this safe to hang onto?
  Dwflst_Process_Tracker *tracker;
  UnwindStatsTable *stats;
  unsigned maxframes;

  int find_procfile(Dwfl *dwfl, pid_t *pid, Elf **elf, int *elf_fd);
  Dwfl *find_dwfl(pid_t pid, const uint64_t *regs, uint32_t nregs,
		  Elf **elf, bool *cached);

public:
  PerfConsumerUnwinder(UnwindSampleConsumer* usc, UnwindStatsTable *ust);
  PerfConsumerUnwinder(UnwindSampleConsumer* usc, UnwindStatsTable *ust, PerfReader *reader);
  ~PerfConsumerUnwinder();

  /* libdwfl{st} callbacks */
  Dwfl *init_dwfl(pid_t pid);
  int unwind_frame_cb(Dwfl_Frame *state);

  void process_comm(const perf_event_header* sample,
		    uint32_t pid, uint32_t tid, bool exec, const string& comm);
  void process_exit(const perf_event_header* sample,
		    uint32_t pid, uint32_t ppid,
		    uint32_t tid, uint32_t ptid);
  void process_fork(const perf_event_header* sample,
		    uint32_t pid, uint32_t ppid,
		    uint32_t tid, uint32_t ptid);
  void process_sample(const perf_event_header* sample,
		      uint64_t ip,
		      uint32_t pid, uint32_t tid,
		      uint64_t time,
		      uint64_t abi,
		      uint32_t nregs, const uint64_t *regs,
		      uint64_t data_size, const uint8_t *data);
  void process_mmap2(const perf_event_header* sample,
		     uint32_t pid, uint32_t tid,
		     uint64_t addr, uint64_t len, uint64_t pgoff,
		     uint8_t build_id_size, const uint8_t *build_id,
		     const char *filename);
};

// An UnwindSampleConsumer receives an UnwindSample from a PerfConsumerUnwinder.
// Pure abstract.
class UnwindSampleConsumer
{
public:
  UnwindSampleConsumer() {}
  virtual ~UnwindSampleConsumer() {}
  virtual void process(const UnwindSample* sample) = 0;
  virtual int maxframes() = 0;
};

// An UnwindStatsConsumer collects basic stats about
// a received stream of UnwindSamples.
class UnwindStatsConsumer: public UnwindSampleConsumer
{
  UnwindStatsTable *stats;

public:
  UnwindStatsConsumer(UnwindStatsTable *usc) : stats(usc) {}
  ~UnwindStatsConsumer();
  void process(const UnwindSample* sample);
  int maxframes();
};

// A GprofUnwindSampleConsumer instance consumes UnwindSamples and tabulates
// them by buildid, for eventual writing out into gmon.out format files.
class GprofUnwindSampleConsumer: public UnwindSampleConsumer
{
  UnwindStatsTable *stats;
  unordered_map<string, string> buildid_to_mainfile;
  unordered_map<string, string> buildid_to_debugfile;
  void record_gmon_hist(ostream &of, map<uint64_t, uint32_t> &histogram, uint64_t low_pc, uint64_t high_pc, uint64_t alignment);

public:
  GprofUnwindSampleConsumer(UnwindStatsTable *usc) : stats(usc) {}
  ~GprofUnwindSampleConsumer(); // writes out all the gmon.$BUILDID.out files
  void record_gmon_out(const string& buildid, UnwindModuleStats& m); // write out one gmon.$BUILDID.out file
  void process(const UnwindSample* sample); // accumulate hits / callgraph edges (need maxdepth=1 only)
  int maxframes();
};

// hypothetical: FlamegraphUnwindSampleConsumer, taking in a bigger maxdepth
// hypothetical: PprofUnwindSampleConsumer, https://github.com/google/pprof


////////////////////////////////////////////////////////////////////////
// command line parsing and main()

/* Name, version, and bug report address.  */
ARGP_PROGRAM_VERSION_HOOK_DEF = print_version;
ARGP_PROGRAM_BUG_ADDRESS_DEF = PACKAGE_BUGREPORT;

#define HIST_SPLIT_OPTS "none/even/flex"

static const struct argp_option options[] =
{
  { NULL, 0, NULL, OPTION_DOC, N_("Output options:"), 1 },
  { "verbose", 'v', NULL, 0, N_("Increase verbosity of logging messages (modules/samples/frames/more)."), 0 },
  /* TODO: Add "quiet" option suppressing summary table. */
  { "gmon", 'g', NULL, 0, N_("Generate gmon.BUILDID.out files for each binary."), 0 },
  { "hist-split", 'G', HIST_SPLIT_OPTS, 0, N_("Split gmon histogram output into even or flexible chunks, default 'even'."), 0 },
  { "maxframes", 'n', "MAXFRAMES", 0, N_("Maximum number of frames to unwind, default 1 with --gmon, 256 otherwise."), 0 },
  { "output", 'o', "DIR", 0, N_("Output directory for gmon.BUILDID.out files."), 0 },
  { "force", 'f', NULL, 0, N_("Unlink output files to force writing as new."), 0 },
  { "pid", 'p', "PID", 0, N_("Profile given PID, and its future children."), 0 },
#ifdef HAVE_PERFMON_PFMLIB_PERF_EVENT_H
  { "event", 'e', "EVENT", 0, N_("Sample given LIBPFM event specification."), 0 },
#define ARGP_KEY_EVENT_LIST 0x1000
  { "event-list", ARGP_KEY_EVENT_LIST, NULL, 0, N_("Sample given LIBPFM event specification."), 0 },
#endif
  { NULL, 0, NULL, 0, NULL, 0 }
};

static error_t parse_opt (int key, char *arg, struct argp_state *state);
static const struct argp argp =
  {
    options, parse_opt, "[--] [CMD]...", N_("Collect systemwide stack-trace profiles."),
    NULL, NULL, NULL
  };

// How to divide the program counter histograms in gmon output:
enum hist_split_method {
  HIST_SPLIT_NONE = 0, /* one histogram for the entire executable */
  HIST_SPLIT_EVEN = 1, /* all histograms the same size */
  HIST_SPLIT_FLEX = 2, /* variable-size histograms */
};

// Globals for command line options:
static unsigned verbose;
static bool gmon;
static hist_split_method gmon_hist_split = HIST_SPLIT_EVEN;
static string output_dir = ".";
static bool output_force = false; // overwrite preexisting output files?
static int pid;
static int opt_maxframes = -1; // set to >= 0 to override default maxframes in consumer
static string libpfm_event;
static string libpfm_event_decoded;
static perf_event_attr attr;
static bool branch_record = false; // use accurate branch recording for call-graph arcs rather than backtrace heuristics

// Verbosity categories:
static bool show_summary = true; /* XXX could suppress with --quiet */
static bool show_modules = false; /* -> first sample for each module */
static bool show_samples = false; /* -> every sample */
static bool show_frames = false;
static bool show_debugfile = false;
static bool show_tmi = false; /* -> perf, cfi details */

static error_t
parse_opt (int key, char *arg, struct argp_state *state)
{
  switch (key)
    {
    case ARGP_KEY_INIT:
      break;

    case 'v':
      verbose ++;
      break;

    case 'g':
      gmon = true;
      break;

    case 'G':
      gmon = true; // Automatically enable gmon mode since a gmon-related option was set.
      if (std::string_view(arg) == "none")
	gmon_hist_split = HIST_SPLIT_NONE;
      else if (std::string_view(arg) == "even")
	gmon_hist_split = HIST_SPLIT_EVEN;
      else if (std::string_view(arg) == "flex")
	gmon_hist_split = HIST_SPLIT_FLEX;
      break;

    case 'o':
      gmon = true;
      output_dir = arg;
      break;

    case 'p':
      pid = atoi(arg);
      if (pid == 0)
	argp_error (state, N_("-p PID should be a positive process id."));
      break;

    case 'n':
      opt_maxframes = atoi(arg);
      if (opt_maxframes < 0)
	{
	  argp_error (state, N_("-n MAXFRAMES should be 0 or higher."));
	  return EINVAL;
	}
      break;

    case 'f':
      output_force = true;
      break;

#ifdef HAVE_PERFMON_PFMLIB_PERF_EVENT_H
    case 'e':
      libpfm_event = arg;
      break;

    case ARGP_KEY_EVENT_LIST:
      {
	pfm_pmu_info_t pinfo;
	pfm_event_info_t info;

	pfm_err_t rc = pfm_initialize();
	if (rc != PFM_SUCCESS)
	  {
	    cerr << format("ERROR: pfm_initialize failed: {}\n", pfm_strerror(rc));
	    exit(1);
	  }

	memset(&pinfo, 0, sizeof(pinfo));
	memset(&info, 0, sizeof(info));
	pinfo.size = sizeof(pinfo);
	info.size = sizeof(info);

	for (int j = PFM_PMU_NONE; j < PFM_PMU_MAX; j++)
	  {
	    pfm_err_t ret = pfm_get_pmu_info((pfm_pmu_t)j, &pinfo);
	    if (ret != PFM_SUCCESS)
	      continue;
	    if (! pinfo.is_present)
	      continue;
	    for (int i = pinfo.first_event; i != -1; i = pfm_get_event_next(i))
	      {
		ret = pfm_get_event_info(i, PFM_OS_PERF_EVENT_EXT, &info);
		if (ret == PFM_SUCCESS)
		  clog << format("{}::{}\n", pinfo.name, info.name);
	      }
	  }
      }
      exit(0);
#endif

    default:
      return ARGP_ERR_UNKNOWN;
    }
  return 0;
}

sig_atomic_t interrupted;

void sigint_handler (int sig)
{
  interrupted ++;
  if (interrupted > 1)
    _exit(1);
}

int main (int argc, char *argv[])
{
  int remaining;
  int pipefd[2] = {-1, -1}; // for post-fork sync with CMD child process
  bool has_cmd = false;
  (void) argp_parse (&argp, argc, argv, 0, &remaining, NULL);

  /* show_summary is true by default */
  if (verbose > 0) show_modules = true;
  if (verbose > 1) show_samples = true;
  if (verbose > 2) show_frames = true;
  if (verbose > 3) show_debugfile = true;
  if (verbose > 4) show_tmi = true;

  if (pid > 0 && remaining < argc) // got a pid AND a cmd? reject
    {
      cerr << format("ERROR: Must not specify both -p PID and CMD\n");
      exit(1);
    }

  bool systemwide = (pid == 0) || (remaining == argc);
  (void) systemwide;

  PerfReader *pr = nullptr;
  UnwindStatsTable *tab = nullptr;
  UnwindSampleConsumer *usc = nullptr;
  PerfConsumerUnwinder *pcu = nullptr;
  StatsPerfConsumer *spc = nullptr;

  try
    {
      memset(&attr, 0, sizeof(attr));
      attr.size = sizeof(attr);

      if (libpfm_event != "")
	{
#if HAVE_PERFMON_PFMLIB_PERF_EVENT_H
	  pfm_err_t rc = pfm_initialize();
	  if (rc != PFM_SUCCESS)
	    {
	      cerr << format("ERROR: pfm_initialize failed: {}\n", pfm_strerror(rc));
	      exit(1);
	    }
	  char *fstr = nullptr;
	  pfm_perf_encode_arg_t arg = { .attr = &attr, .fstr = &fstr, .size = sizeof(arg) };
	  rc = pfm_get_os_event_encoding(libpfm_event.c_str(),
					 PFM_PLM3, /* userspace, whether systemwide or not */
					 PFM_OS_PERF_EVENT_EXT, &arg);
	  if (rc != PFM_SUCCESS)
	    {
	      cerr << format("ERROR: pfm_get_os_event_encoding failed: {}\n", pfm_strerror(rc));
	      exit(1);
	    }
	  if (verbose)
	    {
	      clog << format("libpfm expanded {} to {}\n", libpfm_event, fstr);
	    }
	  libpfm_event_decoded = fstr; // overwrite
	  free(fstr);
#endif
	}
      else
	{
	  // same as: -e perf::CPU-CLOCK:freq=1000
	  attr.type = PERF_TYPE_SOFTWARE;
	  attr.config = PERF_COUNT_SW_CPU_CLOCK;
	  attr.sample_freq = 1000;
	  attr.freq = 1;
	  attr.exclude_kernel = 1;
	  attr.exclude_hv = 1;
	  attr.exclude_guest = 1;
	}

      if (show_summary)
	{
	  clog << format("perf_event_attr configuration type={:x} config={:x} {}{}\n",
			 attr.type, attr.config,
			 (attr.freq ? "sample_freq=" : "sample_period="),
			 (attr.freq ? attr.sample_freq : attr.sample_period));
	  clog << endl;
	}

      if (remaining < argc) // got a CMD... suffix?  ok start it
	{
	  has_cmd = true;
	  int rc = pipe(pipefd);
	  if (rc < 0)
	    {
	      cerr << format("ERROR: pipe failed: {}\n", strerror(errno));
	      exit(1);
	    }

	  pid = fork();
	  if (pid == 0) // in child
	    {
	      close(pipefd[1]); // close write end
	      char dummy;
	      int rc = read(pipefd[0], &dummy, 1); // block until parent is ready
	      if (rc != 1)
		{
		  cerr << format("ERROR: child sync read failed: {}\n", strerror(errno));
		  exit(1);
		}
	      close(pipefd[0]);
	      execvp(argv[remaining], &argv[remaining] /* including child argv[0] */);
	      // fallthrough
	      cerr << format("ERROR: execvp failed: {}\n", strerror(errno));
	      exit(1);
	    }
	  else if (pid > 0) // in parent
	    {
	      close(pipefd[0]); // close read end
	      // will write to pipefd[1] after perfreader sicced at child
	    }
	  else // error
	    {
	      cerr << format("ERROR: fork failed: {}\n", strerror(errno));
	      exit(1);
	    }
	}

      // Create the perf processing pipeline:
      if (gmon)
	{
	  tab = new UnwindStatsTable();
	  usc = new GprofUnwindSampleConsumer(tab);
	  pcu = new PerfConsumerUnwinder(usc, tab);
	  pr = new PerfReader(&attr, pcu, pid);
	}
      else
	{
#ifndef STACKPROF_STATS_DEBUG
	  tab = new UnwindStatsTable();
	  usc = new UnwindStatsConsumer(tab);
	  pcu = new PerfConsumerUnwinder(usc, tab);
	  pr = new PerfReader(&attr, pcu, pid);
#else
	  /* early debug mode */
	  spc = new StatsPerfConsumer();
	  pr = new PerfReader(&attr, spc, pid);
#endif
	}

      signal(SIGINT, sigint_handler);
      signal(SIGTERM, sigint_handler);

      if (pid > 0 && has_cmd) // need to release child CMD process?
	{
	  int rc = write(pipefd[1], "x", 1); // unblock child
	  assert (rc == 1); // XXX
	  close(pipefd[1]);
	}

      if (show_summary) // TODO: move before child CMD release
	{
	  clog << "Starting stack profile collection ";
	  if (pid) clog << format("pid {}", pid);
	  else clog << "systemwide";
	  clog << "\n"; // TODO: replace with endl throughout?
	}

      while (true) // main loop
	{
	  if (interrupted) break;
	  if (pid > 0) waitpid(pid, NULL, WNOHANG); // reap dead child to allow kill(pid, 0) to signal death
	  if (pid > 0 && kill(pid, 0) != 0) break; // exit if child or targeted non-child process died
	  pr->process_some();
	}

      delete pr;
      delete usc;
      delete pcu;
      delete spc;
      delete tab;
      // reporting done in various destructors
    }
  catch (const exception& e)
    {
      cerr << format("{}\n", e.what());
      // XXX for now, call only the destructors that do not print anything:
      delete pr;
      delete pcu;
      delete tab;
      return 1;
    }

  return 0;
}


////////////////////////////////////////////////////////////////////////
// perf reader

PerfReader::PerfReader(perf_event_attr* attr, PerfConsumer* consumer, int pid)
{
  this->page_size = getpagesize();
  this->page_count = 64; /* XXX May want to verify if this is a large-enough power-of-2.  */
  this->mmap_size = this->page_size * (this->page_count + 1); // total mmap size, including header page
  this->event_wraparound_temp.resize(this->mmap_size); // NB: never resize again!
  this->consumer = consumer;
  this->consumer->set_reader(this);
  this->enabled = false;

  struct utsname u;
  uname(&u);
  /* XXX Possibly could be a libdwfl api, but can't be libebl since it
     must be accessible by external tools.  */
  int em = dwflst_arch_from_uname(u.machine);
  if (em == EM_NONE) {
    cerr << format("ERROR: Unsupported architecture: {}\n", u.machine);
    exit(1);
  }
  this->default_ebl = ebl_openbackend_machine(em);
  this->sample_regs_user = ebl_perf_frame_regs_mask (this->default_ebl);
  this->sample_regs_count = bitset<64>(this->sample_regs_user).count();

  attr->sample_regs_user = this->sample_regs_user;
  attr->sample_stack_user = 8192; // enough?
  attr->sample_type = (PERF_SAMPLE_IP | PERF_SAMPLE_TID | PERF_SAMPLE_TIME);
  attr->sample_type |= PERF_SAMPLE_REGS_USER;
  attr->sample_type |= PERF_SAMPLE_STACK_USER;
  // XXX Maybe: ask for PERF_SAMPLE_CALLCHAIN, in case kernel can
  // unwind for us?  Would want an option to control this, to allow
  // eu-stackprof to exercise our own unwinding functionality when
  // testing.
  attr->mmap = 1;
  attr->mmap2 = 1;
  attr->exclude_kernel = 1; /* in-kernel unwinding not relevant for our usecase */
  attr->disabled = 1; /* will get enabled soon */
  attr->task = 1; // catch FORK/EXIT
  attr->comm = 1; // catch EXEC
  attr->comm_exec = 1; // catch EXEC
  // attr->precise_ip = 2; // request 0 skid ... but that conflicts with PERF_COUNT_HW_BRANCH_INSTRUCTIONS:freq=4000
  attr->build_id = 1; // request build ids in MMAP2 events

  if (pid > 0) // actually only once, to allow break in case of error
    attr->inherit = 1; // propagate to child processes

  if (show_tmi)
    {
      clog << "perf_event_attr hexdump: ";
      auto bytes = (unsigned char *)attr;
      for (size_t x = 0; x < sizeof(*attr); x++)
	clog << ((x % 8) ? "" : " ")
	     << ((x % 32) ? "" : "\n")
	     << format("{:02x}", (unsigned)bytes[x]);
      clog << "\n";
    }

  // Iterate over all cpus to handle possible concurrency, even if
  // attaching to a single pid, because we set ->inherit=1.
  int ncpus = sysconf(_SC_NPROCESSORS_CONF);
  for (int cpu = 0; cpu < ncpus; cpu++)
    {
      int fd = syscall(__NR_perf_event_open, attr,
		       (pid > 0 ? pid : -1), cpu, -1,
		       PERF_FLAG_FD_CLOEXEC);
      if (fd < 0)
	{
	  cerr << format("WARNING: unable to open perf fd for cpu {}: {}\n", cpu, strerror(errno));
	  continue;
	}
      void *buf = mmap(NULL, this->mmap_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
      if (buf == MAP_FAILED)
	{
	  cerr << format("ERROR: perf event mmap failed: {}\n", strerror(errno));
	  close(fd);
	  continue;
	}
      this->perf_fds.push_back(fd);
      this->perf_headers.push_back((perf_event_mmap_page *)buf);
      struct pollfd pfd = { .fd = fd, .events = POLLIN };
      this->pollfds.push_back(pfd);
    }

  if (this->perf_fds.size() == 0)
    throw runtime_error("ERROR: no perf fds opened");
}

PerfReader::~PerfReader()
{
  for (auto fd : this->perf_fds)
    close(fd);
  for (auto m : this->perf_headers)
    munmap((void *)m, this->mmap_size);
  ebl_closebackend (this->default_ebl);
}

uint64_t millis_monotonic()
{
  return chrono::duration_cast<chrono::milliseconds>(chrono::steady_clock::now().time_since_epoch()).count();
}

static inline uint64_t
ring_buffer_read_head(volatile struct perf_event_mmap_page *base)
{
  uint64_t head = base->data_head;
  asm volatile("" ::: "memory"); // memory fence
  return head;
}

static inline void
ring_buffer_write_tail(volatile struct perf_event_mmap_page *base,
		       uint64_t tail)
{
  asm volatile("" ::: "memory"); // memory fence
  base->data_tail = tail;
}

// TODO: diagnostics to see how well the buffer processing keeps from overflow
void PerfReader::process_some()
{
  if (!this->enabled)
    {
      for (auto fd : this->perf_fds)
	ioctl(fd, PERF_EVENT_IOC_ENABLE, 0 /* value ignored */);
      this->enabled = true;
    }

  uint64_t starttime = millis_monotonic();
  uint64_t endtime = starttime + 1000; // run at most for one second
  uint64_t ring_buffer_size = this->page_size * this->page_count; // just the ring buffer size

  while (!interrupted)
    {
      uint64_t now = millis_monotonic();
      if (endtime < now)
	break;
      int ready = poll(this->pollfds.data(), this->pollfds.size(), (int)(endtime-now)); // wait a little while
      if (ready < 0)
	break;

      for (size_t i = 0; i < pollfds.size(); i++)
	if (this->pollfds[i].revents & POLLIN) // found an fd with fresh yummy events
	  {
	    perf_event_mmap_page *header = perf_headers[i];
	    uint64_t data_head = ring_buffer_read_head(header);
	    uint64_t data_tail = header->data_tail;
	    uint8_t *base = ((uint8_t *)header) + this->page_size;
	    struct perf_event_header *ehdr;
	    size_t ehdr_size;

	    while (data_head != data_tail) // consume all packets in ring buffer XXX why?
	      {
		ehdr = (perf_event_header *) (base + (data_tail & (ring_buffer_size - 1)));
		ehdr_size = ehdr->size;
		if (show_tmi)
		  clog << format("perf head={:p} tail={:p} ehdr={:p} size={:d}{:x}\n",
				 (void *)data_head, (void *)data_tail, (void *)ehdr, ehdr_size, 0);

		if (((uint8_t *)ehdr) + ehdr_size > base + ring_buffer_size) // mmap region wraparound?
		  {
		    // need to copy it to a contiguous temporary
		    uint8_t *copy_start = (uint8_t *)ehdr;
		    size_t len_first = base + ring_buffer_size - copy_start;
		    size_t len_secnd = ehdr_size - len_first;
		    uint8_t *event_temp = this->event_wraparound_temp.data();
		    memcpy(event_temp, copy_start, len_first);       // part at end of mmap'd region
		    memcpy(event_temp + len_first, base, len_secnd); // part at beginning of mmap'd region
		    ehdr = (perf_event_header *)event_temp;
		  }

		this->decode_event(ehdr);
		data_tail += ehdr_size;
	      }

	    ring_buffer_write_tail(header, data_tail);
	  }
    }
}

void PerfReader::decode_event(const perf_event_header* ehdr)
{
  consumer->process(ehdr); // allow general processing

  // ... and decode into individual event types
  switch (ehdr->type)
    {
    case PERF_RECORD_SAMPLE:
      {
	const uint8_t *data = reinterpret_cast<const uint8_t *>(ehdr) + sizeof(perf_event_header);
	uint64_t ip = *reinterpret_cast<const uint64_t *>(data); data += sizeof(uint64_t);
	uint32_t pid = *reinterpret_cast<const uint32_t *>(data); data += sizeof(uint32_t);
	uint32_t tid = *reinterpret_cast<const uint32_t *>(data); data += sizeof(uint32_t);
	uint64_t time = *reinterpret_cast<const uint64_t *>(data); data += sizeof(uint64_t);
	// PERF_SAMPLE_CALLCHAIN would be here if requested
	uint64_t abi = *reinterpret_cast<const uint64_t *>(data); data += sizeof(uint64_t);
	uint32_t nregs = this->sample_regs_count;
	const uint64_t *regs = reinterpret_cast<const uint64_t *>(data); data += nregs * sizeof(uint64_t);
	uint64_t data_size = *reinterpret_cast<const uint64_t *>(data); data += sizeof(uint64_t);
	const uint8_t *stack_data = data;
	consumer->process_sample(ehdr, ip, pid, tid, time, abi, nregs, regs, data_size, stack_data);
	break;
      }
    case PERF_RECORD_COMM:
      {
	const uint8_t *data = reinterpret_cast<const uint8_t *>(ehdr) + sizeof(perf_event_header);
	uint32_t pid = *reinterpret_cast<const uint32_t *>(data); data += sizeof(uint32_t);
	uint32_t tid = *reinterpret_cast<const uint32_t *>(data); data += sizeof(uint32_t);
	const char *comm = reinterpret_cast<const char *>(data);
	consumer->process_comm(ehdr, pid, tid, (ehdr->misc & PERF_RECORD_MISC_COMM_EXEC)/* XXX why? */, comm);
	break;
      }
    case PERF_RECORD_EXIT:
      {
	const uint8_t *data = reinterpret_cast<const uint8_t *>(ehdr) + sizeof(perf_event_header);
	uint32_t pid = *reinterpret_cast<const uint32_t *>(data); data += sizeof(uint32_t);
	uint32_t ppid = *reinterpret_cast<const uint32_t *>(data); data += sizeof(uint32_t);
	uint32_t tid = *reinterpret_cast<const uint32_t *>(data); data += sizeof(uint32_t);
	uint32_t ptid = *reinterpret_cast<const uint32_t *>(data);
	consumer->process_exit(ehdr, pid, ppid, tid, ptid);
	break;
      }
    case PERF_RECORD_FORK:
      {
	const uint8_t *data = reinterpret_cast<const uint8_t *>(ehdr) + sizeof(perf_event_header);
	uint32_t pid = *reinterpret_cast<const uint32_t *>(data); data += sizeof(uint32_t);
	uint32_t ppid = *reinterpret_cast<const uint32_t *>(data); data += sizeof(uint32_t);
	uint32_t tid = *reinterpret_cast<const uint32_t *>(data); data += sizeof(uint32_t);
	uint32_t ptid = *reinterpret_cast<const uint32_t *>(data);
	consumer->process_fork(ehdr, pid, ppid, tid, ptid);
	break;
      }
    case PERF_RECORD_MMAP2:
      {
	const uint8_t *data = reinterpret_cast<const uint8_t *>(ehdr) + sizeof(perf_event_header);
	uint32_t pid = *reinterpret_cast<const uint32_t *>(data); data += sizeof(uint32_t);
	uint32_t tid = *reinterpret_cast<const uint32_t *>(data); data += sizeof(uint32_t);
	uint64_t addr = *reinterpret_cast<const uint64_t *>(data); data += sizeof(uint64_t);
	uint64_t len = *reinterpret_cast<const uint64_t *>(data); data += sizeof(uint64_t);
	uint64_t pgoff = *reinterpret_cast<const uint64_t *>(data); data += sizeof(uint64_t);
	uint8_t build_id_size = 0;
	const uint8_t *build_id = nullptr;
	if (ehdr->misc & PERF_RECORD_MISC_MMAP_BUILD_ID)
	  {
	    build_id_size = *reinterpret_cast<const uint8_t *>(data); data += sizeof(uint8_t);
	    data += sizeof(uint8_t) + sizeof(uint16_t); // skip padding
	    build_id = reinterpret_cast<const uint8_t *>(data);
	    data += build_id_size;
	  }
	else
	  {
	    data += 4 + 4 + 8 + 8; // skip maj, min, ino, ino_generation
	  }
	data += 2 * sizeof(uint32_t); // skip prot, flags
	const char *filename = reinterpret_cast<const char *>(data);
	consumer->process_mmap2(ehdr, pid, tid, addr, len, pgoff, build_id_size, build_id, filename);
	break;
      }
    default:
      break;
    }
}


////////////////////////////////////////////////////////////////////////
// perf event consumers

void StatsPerfConsumer::process_comm(const perf_event_header *sample,
				     uint32_t pid, uint32_t tid, bool exec, const string &comm)
{
  if (show_modules)
    {
      clog << format("process_comm: pid={} tid={} exec={} comm={}\n", pid, tid, exec, comm);
    }
}

void StatsPerfConsumer::process_exit(const perf_event_header *sample,
				     uint32_t pid, uint32_t ppid,
				     uint32_t tid, uint32_t ptid)
{
  if (show_modules)
    {
      clog << format("process_exit: pid={} ppid={} tid={} ptid={}\n", pid, ppid, tid, ptid);
    }
}

void StatsPerfConsumer::process_fork(const perf_event_header *sample,
				     uint32_t pid, uint32_t ppid,
				     uint32_t tid, uint32_t ptid)
{
  if (show_modules)
    {
      clog << format("process_fork: pid={} ppid={} tid={} ptid={}\n", pid, ppid, tid, ptid);
    }
}

void StatsPerfConsumer::process_sample(const perf_event_header *sample,
				       uint64_t ip,
				       uint32_t pid, uint32_t tid,
				       uint64_t time,
				       uint64_t abi,
				       uint32_t nregs, const uint64_t *regs,
				       uint64_t data_size, const uint8_t *data)
{
  if (show_samples)
    {
      clog << format("process_sample: pid={:d} tid={:d} ip={:x} time={:d} abi={:d} nregs={:d} data_size={:d}\n",
		     pid, tid, ip, time, abi, nregs, data_size);
    }
}

void StatsPerfConsumer::process_mmap2(const perf_event_header *sample,
				      uint32_t pid, uint32_t tid,
				      uint64_t addr, uint64_t len, uint64_t pgoff,
				      uint8_t build_id_size, const uint8_t *build_id,
				      const char *filename)
{
  if (show_modules)
    {
      clog << format("process_mmap2: pid={:d} tid={:d} addr={:x} len={:x} pgoff={:x} build_id_size={:d} filename={:s}\n",
		     pid, tid, addr, len, pgoff, (unsigned)build_id_size, filename);
    }
}

StatsPerfConsumer::~StatsPerfConsumer()
{
  for (const auto& kv : this->event_type_counts)
    {
      // TODO: Decode event type.
      clog << format("event type {} count {}\n", kv.first, kv.second);
    }
}

void StatsPerfConsumer::process(const perf_event_header* ehdr)
{
  this->event_type_counts[ehdr->type] ++;
}


////////////////////////////////////////////////////////////////////////
// unwind stats table for PerfConsumerUnwinder + downstream consumers

UnwindDwflStats *UnwindStatsTable::pid_find_or_create (pid_t pid)
{
  if (this->dwfl_tab.count(pid) == 0)
    this->dwfl_tab.emplace(pid, UnwindDwflStats());
  return &this->dwfl_tab[pid];
}

static const string unknown_comm = "<unknown>";

string UnwindStatsTable::pid_find_comm (pid_t pid)
{
  UnwindDwflStats *entry = this->pid_find_or_create(pid);
  if (entry == NULL)
    return unknown_comm;
  if (!entry->comm.empty())
    return entry->comm;
  string name = format("/proc/{}/comm", pid);
  ifstream procfile(name);
  string buf;
  if (!procfile || !getline(procfile, buf))
    entry->comm = unknown_comm;
  else
    entry->comm = buf;

  return entry->comm;
}

Dwfl *UnwindStatsTable::pid_find_dwfl (pid_t pid)
{
  if (this->dwfl_tab.count(pid) == 0)
    return NULL;
  return this->dwfl_tab[pid].dwfl;
}

void UnwindStatsTable::pid_store_dwfl (pid_t pid, Dwfl *dwfl)
{
  UnwindDwflStats *entry = this->pid_find_or_create(pid);
  if (entry == NULL)
    return;
  entry->dwfl = dwfl;
  if (show_summary)
    this->pid_find_comm(pid);
  return;
}

UnwindModuleStats *UnwindStatsTable::buildid_find (string buildid)
{
  if (this->buildid_tab.count(buildid) == 0)
    return NULL;
  return &this->buildid_tab[buildid];
}

UnwindModuleStats *UnwindStatsTable::buildid_find_or_create (string buildid, Dwfl_Module *mod)
{
  if (this->buildid_tab.count(buildid) == 0)
    {
      this->buildid_tab.emplace(buildid, UnwindModuleStats());
      /* TODO: Guess text range for mod? */
      (void)mod;
    }
  return &this->buildid_tab[buildid];
}

void UnwindStatsTable::print_summary () const
{
#define PERCENT(x,tot) ((x+tot == 0)?0.0:((double)x)/((double)tot)*100.0)
  int total_samples = 0;
  int total_lost_samples = 0;
  clog << "\n=== pid / sample counts ===\n";
  for (auto& p : this->dwfl_tab)
    {
      pid_t pid = p.first;
      const UnwindDwflStats& d = p.second;
      clog << format(N_("{} {} -- max {} frames, received {} samples, lost {} samples ({:.1f}%) (last {}, worst {})\n"),
		     pid, d.comm, d.max_frames,
		     d.total_samples, d.lost_samples,
		     PERCENT(d.lost_samples, d.total_samples),
		     dwfl_unwound_source_str(d.last_unwound),
		     dwfl_unwound_source_str(d.worst_unwound));
      total_samples += d.total_samples;
      total_lost_samples += d.lost_samples;
    }
  clog << "===\n";
  clog << format(N_("TOTAL -- received {} samples, lost {} samples, loaded {} processes\n"),
		 total_samples, total_lost_samples,
		 this->dwfl_tab.size() /* TODO: If implementing eviction, need to maintain a separate count of evicted pids. */);
  clog << "\n";
#undef PERCENT
}


////////////////////////////////////////////////////////////////////////
// real perf consumer: unwind helpers

PerfConsumerUnwinder::PerfConsumerUnwinder(UnwindSampleConsumer *usc, UnwindStatsTable *ust)
  : consumer(usc), stats(ust)
{
  maxframes = usc->maxframes();
  this->tracker = dwflst_tracker_begin(&dwfl_cfi_callbacks);
}

PerfConsumerUnwinder::PerfConsumerUnwinder(UnwindSampleConsumer *usc, UnwindStatsTable *ust, PerfReader *reader)
  : consumer(usc), stats(ust)
{
  maxframes = usc->maxframes();
  this->reader = reader;
  this->tracker = dwflst_tracker_begin(&dwfl_cfi_callbacks);
}

PerfConsumerUnwinder::~PerfConsumerUnwinder()
{
  dwflst_tracker_end(this->tracker);
}

/* TODO: Could be relocated to libdwfl/linux-pid-attach.c
   to remove some duplication of existing linux-pid-attach code.  */
int PerfConsumerUnwinder::find_procfile(Dwfl *dwfl, pid_t *pid, Elf **elf, int *elf_fd)
{
  int err = 0; /* The errno to return. XXX libdwfl would also set this for dwfl->attacherr.  */

  /* Make sure to report the actual PID (thread group leader) to
     dwfl_attach_state.  */
  string buffer = format("/proc/{}/status", *pid);
  ifstream procfile(buffer);
  if (!procfile)
    {
      err = errno;
    fail:
      return err;
    }

  string line;
  while (getline (procfile, line))
    if (startswith (line.c_str(), "Tgid:"))
      {
	errno = 0;
	char *endptr;
	long val = strtol (&line.c_str()[5], &endptr, 10);
	if ((errno == ERANGE && val == LONG_MAX)
	    || (*endptr != 0 && *endptr != '\n')
	       /* <- getline(3) ambiguous on what ends the string */
	    || val < 0 || val != (pid_t) val)
	  *pid = 0;
	else
	  *pid = (pid_t) val;
	break;
      }

  if (*pid == 0)
    {
      err = ESRCH;
      goto fail;
    }

  {
    string name = format("/proc/{}/task", *pid);
    DIR *dir = opendir(name.c_str());
    if (dir == NULL)
      {
	err = errno;
	goto fail;
      }
    else
      closedir(dir);
  }

  {
    string name = format("/proc/{}/exe", *pid);
    *elf_fd = open(name.c_str(), O_RDONLY);
  }

  if (*elf_fd >= 0)
    {
      *elf = elf_begin(*elf_fd, ELF_C_READ_MMAP, NULL);
      if (*elf == NULL)
	{
	  /* Just ignore, dwfl_attach_state will fall back to trying
	     to associate the Dwfl with one of the existing Dwfl_Module
	     ELF images (to know the machine/class backend to use).  */
	  if (verbose)
	    cerr << format(N_("WARNING: find_procfile pid {}: elf not found\n"), (long long) *pid);
	  close(*elf_fd);
	  *elf_fd = -1;
	}
    }
  else
    *elf = NULL;
  return 0;
}

Dwfl *PerfConsumerUnwinder::init_dwfl(pid_t pid)
{
  Dwfl *dwfl = dwflst_tracker_dwfl_begin(this->tracker);

  int err = dwfl_linux_proc_report(dwfl, pid);
  if (err < 0)
    {
      if (verbose)
	cerr << format("WARNING: dwfl_linux_proc_report pid {}: {}\n", (long long) pid, dwfl_errmsg(-1));
      return NULL;
    }
  err = dwfl_report_end(dwfl, NULL, NULL);
  if (err != 0)
    {
      if (verbose)
	cerr << format("WARNING: dwfl_report_end pid {}: {}\n", (long long) pid, dwfl_errmsg(-1));
      return NULL;
    }

  return dwfl;
}

Dwfl *pcu_init_dwfl_cb (Dwflst_Process_Tracker *cb_tracker __attribute__ ((unused)),
			pid_t pid,
			void *arg)
{
  PerfConsumerUnwinder *pcu = (PerfConsumerUnwinder *)arg;
  return pcu->init_dwfl(pid);
}

Dwfl *PerfConsumerUnwinder::find_dwfl(pid_t pid, const uint64_t *regs, uint32_t nregs,
				      Elf **out_elf, bool *cached)
{
  int machine = ebl_get_elfmachine(this->reader->ebl());
  if (nregs < dwflst_arch_expected_frame_nregs(machine))
    {
      if (verbose)
	cerr << format(N_("WARNING: find_dwfl: nregs={}, expected at least {}\n"), nregs, ebl_frame_nregs(this->reader->ebl()));
      return NULL;
    }

  Elf *elf = NULL;
  Dwfl *dwfl = dwflst_tracker_find_pid(this->tracker, pid, pcu_init_dwfl_cb, this);
  int elf_fd = -1;
  int err;
  if (dwfl != NULL && dwfl_pid(dwfl) != -1 /* dwfl is attached */)
    {
      *cached = true;
      goto reuse;
    }
  err = this->find_procfile(dwfl, &pid, &elf, &elf_fd);
  if (err != 0)
    {
      if (verbose)
	cerr << format("WARNING: find_procfile pid {}: {}\n", (long long) pid, dwfl_errmsg(-1));
      return NULL;
    }

 reuse:
  bool is_abi32 = this->last_us.elfclass == ELFCLASS32;
  int user_regs_sp = dwflst_arch_sp_perf_reg(machine, this->reader->regs_mask(), is_abi32);
  /* Bounds check, unlikely to fail:  */
  this->last_us.sp = user_regs_sp >= 0 ? regs[user_regs_sp] : 0;
  this->last_us.base = this->last_us.sp;

  if (!*cached)
    this->stats->pid_store_dwfl(pid, dwfl);
  *out_elf = elf;
  return dwfl;
}

int PerfConsumerUnwinder::unwind_frame_cb(Dwfl_Frame *state)
{
  Dwarf_Addr pc;
  bool isactivation;
  if (! dwfl_frame_pc(state, &pc, &isactivation))
    {
      if (verbose)
	cerr << format("WARNING: dwfl_frame_pc: {}\n", dwfl_errmsg(-1));
      return DWARF_CB_ABORT;
    }

  Dwarf_Addr pc_adjusted = pc - (isactivation ? 0 : 1);
  Dwarf_Addr sp;

  int is_abi32 = (this->last_us.elfclass == ELFCLASS32);
  int m = ebl_get_elfmachine(this->reader->ebl());
  int user_regs_sp = dwflst_arch_sp_dwarf_reg(m, is_abi32);
  /* Bounds check, unlikely to fail:  */
  int rc = user_regs_sp >= 0 ? dwfl_frame_reg(state, user_regs_sp, &sp) : -1;
  if (rc < 0)
    {
      if (verbose && user_regs_sp < 0)
	cerr << "WARNING: dwflst_arch_sp_dwarf_reg: arch unsupported\n";
      else if (verbose)
	cerr << format("WARNING: dwfl_frame_reg: {}\n", dwfl_errmsg(-1));
      return DWARF_CB_ABORT;
    }

  UnwindDwflStats *dwfl_ent = this->stats->pid_find_or_create(this->last_us.pid);
  if (dwfl_ent != NULL)
    {
      Dwfl_Unwound_Source unwound_source = dwfl_frame_unwound_source(state);
      if (unwound_source > dwfl_ent->worst_unwound)
	dwfl_ent->worst_unwound = unwound_source;
      dwfl_ent->last_unwound = unwound_source;
      if (show_frames)
	{
	  Dwfl_Module *m = dwfl_addrmodule(this->last_us.dwfl, pc);
	  uint64_t rel_pc = pc_adjusted;
	  int j = dwfl_module_relocate_address(m, &rel_pc);
	  (void) j;
	  clog << format("* frame {:d}: rel_pc={:x} raw_pc={:x} sp={:x}+{:x} [{}]\n",
			 this->last_us.addrs.size(), rel_pc, pc_adjusted, this->last_us.base, (sp - this->last_us.base), dwfl_unwound_source_str(unwound_source));
	}
    }
  else
    {
      if (show_frames)
	{
	  Dwfl_Module *m = dwfl_addrmodule(this->last_us.dwfl, pc);
	  uint64_t rel_pc = pc_adjusted;
	  int j = dwfl_module_relocate_address(m, &rel_pc);
	  (void) j;
	  clog << format(N_("* frame {:d}: rel_pc={:x} raw_pc={:x} sp={:x}+{:x} [dwfl_ent not found]\n"),
			 this->last_us.addrs.size(), rel_pc, pc_adjusted, this->last_us.base, (sp - this->last_us.base));
	}
    }
  if (show_debugfile)
    {
      Dwfl_Module *m = dwfl_addrmodule(this->last_us.dwfl, pc);
      if (m == NULL)
	{
	  clog << format("* pid {:d} pc={:x} -> MODULE NOT FOUND\n",
			 this->last_us.pid, pc);
	}
      else
	{
	  const unsigned char *desc;
	  GElf_Addr vaddr;
	  int build_id_len = dwfl_module_build_id(m, &desc, &vaddr);
	  clog << format("* pid {:d} build_id=", this->last_us.pid);
	  for (int i = 0; i < build_id_len; ++i)
	    clog << format("{:02x}", static_cast<int>(desc[i]));

	  const char *mainfile;
	  const char *debugfile;
	  const char *modname = dwfl_module_info(m, NULL, NULL, NULL, NULL,
						 NULL, &mainfile, &debugfile);
	  clog << format("module={} mainfile={} debugfile={}\n",
			 modname,
			 mainfile ? mainfile : "<none>",
			 debugfile ? debugfile : "<none>");
	  /* TODO: Also store this data to avoid repeated extraction for
	     the final buildid summary?  */
#ifdef DEBUG_MODULES
	  Dwarf_Addr bias;
	  Dwarf_CFI *cfi_eh = dwfl_module_eh_cfi(m, &bias);
	  if (cfi_eh == NULL)
	    clog << format("* pc={:x} -> NO EH_CFI\n", pc);
#endif
	}
    }

  this->last_us.sp = sp;
  this->last_us.addrs.push_back(pc);

  /* e.g. gmon callgraphs only requires maxframes=1
     (initial pc + one frame for caller ID only)  */
  if (this->last_us.addrs.size() > this->maxframes)
    {
      /* XXX without maxframes, very rarely, the unwinder can loop
	 infinitely; worth investigating?  */
      return DWARF_CB_ABORT;
    }
  return DWARF_CB_OK;
}

int pcu_unwind_frame_cb(Dwfl_Frame *state, void *arg)
{
  PerfConsumerUnwinder *pcu = (PerfConsumerUnwinder *)arg;
  return pcu->unwind_frame_cb(state);
}


////////////////////////////////////////////////////////////////////////
// real perf consumer: event handler callbacks

void PerfConsumerUnwinder::process_comm(const perf_event_header *sample,
					uint32_t pid, uint32_t tid, bool exec, const string &comm)
{
  // NB: Could have dwflst ditch data for process and start anew, if EXEC.
  // XXX: is this needed to avoid gradual memory leaks or pid reuse?
}

void PerfConsumerUnwinder::process_exit(const perf_event_header *sample,
					uint32_t pid, uint32_t ppid,
					uint32_t tid, uint32_t ptid)
{
  // NB: Could have dwflst ditch data for process.
  // XXX: is this needed to avoid gradual memory leaks of pid reuse?
}

void PerfConsumerUnwinder::process_fork(const perf_event_header *sample,
					uint32_t pid, uint32_t ppid,
					uint32_t tid, uint32_t ptid)
{
  // NB: Could have dwflst begin tracking a new process, but
  // this will likely happen automatically when a packet is received
  // from it.  The short duration between fork/exec typically means
  // elfutils will pick up on the post-exec process -- we would have
  // to work hard to replicate a situation where
  // process_fork/process_comm handling are needed.
}

void PerfConsumerUnwinder::process_sample(const perf_event_header *sample,
					  uint64_t ip,
					  uint32_t pid, uint32_t tid,
					  uint64_t time,
					  uint64_t abi,
					  uint32_t nregs, const uint64_t *regs,
					  uint64_t data_size, const uint8_t *data)
{
  string comm;
  if (show_summary)
    comm = this->stats->pid_find_comm(pid);

  if (show_frames)
    clog << "\n"; /* extra newline for padding */

  Elf *elf = NULL; // Released during dwflst_tracker_end
  bool cached = false;
  Dwfl *dwfl = this->find_dwfl(pid, regs, nregs, &elf, &cached);
  UnwindDwflStats *dwfl_ent = NULL;
  bool first_load = false; /* -> for show_modules: pid is loaded first time */
  if (verbose || show_summary || show_modules)
    {
      if (dwfl_ent == NULL)
	dwfl_ent = this->stats->pid_find_or_create(pid);
      if (dwfl_ent->total_samples == 0)
	first_load = true;
    }
  if (dwfl == NULL)
    {
      if (show_summary || show_modules)
	{
	  /* dwfl_ent loaded above */
	  dwfl_ent->total_samples++;
	  dwfl_ent->lost_samples++;
	}
      if (verbose && show_summary)
	{
	  cerr << format("WARNING: find_dwfl pid {} ({}) (failed)\n", (long long)pid, comm);
	}
      else if (verbose) // XXX
	{
	  cerr << format("WARNING: find_dwfl pid {} (failed)\n", (long long)pid);
	}
      return;
    }

  if (show_samples || (first_load && show_modules))
    {
      bool is_abi32 = (abi == PERF_SAMPLE_REGS_ABI_32);
      clog << format("find_dwfl {}pid {:d} {}({}): hdr_size={:d} size={:d}{} pc={:x} sp={:x}+{:d}\n",
		     first_load ? "newly seen " : "", (long long)pid,
		     (cached ? "(cached) " : ""), comm,
		     sample->size, data_size,
		     (is_abi32 ? " (32-bit)" : ""), ip,
		     this->last_us.base, 0);
    }

  this->last_us.addrs.clear();
  this->last_us.elfclass = (abi == PERF_SAMPLE_REGS_ABI_32 ? ELFCLASS32 : ELFCLASS64);
  this->last_us.dwfl = dwfl;
  this->last_us.pid = pid;
  int rc = dwflst_perf_sample_getframes(dwfl, elf, pid, tid,
					data, data_size,
					regs, nregs,
					this->reader->regs_mask(), abi,
					pcu_unwind_frame_cb, this);
  if (rc < 0)
    {
      /* dwfl_ent loaded above */
      if (verbose && dwfl_ent->shown_errors < 10)
	{
	  dwfl_ent->shown_errors ++;
	  cerr << format("WARNING: dwflst_perf_sample_getframes pid {}: {}{}\n",
			 (long long)pid, dwfl_errmsg(-1),
			 dwfl_ent->shown_errors >= 10 ?
			 " (...suppressing further warnings for this pid)" : "");
	}
    }
  if (show_summary)
    {
      /* For final diagnostics.  dwfl_ent loaded above */
      if (this->last_us.addrs.size() > (unsigned long)dwfl_ent->max_frames)
	dwfl_ent->max_frames = this->last_us.addrs.size();
      dwfl_ent->total_samples++;
      if (this->maxframes > 2 && this->last_us.addrs.size() <= 2)
	dwfl_ent->lost_samples++;
    }

  this->consumer->process(&this->last_us);
  return;
}

void PerfConsumerUnwinder::process_mmap2(const perf_event_header *sample,
					 uint32_t pid, uint32_t tid,
					 uint64_t addr, uint64_t len, uint64_t pgoff,
					 uint8_t build_id_size, const uint8_t *build_id,
					 const char *filename)
{
  Dwfl *dwfl = this->stats->pid_find_dwfl(pid);
  if (dwfl != NULL)
    {
      dwfl_report_begin_add(dwfl);
      dwfl_report_module(dwfl, filename, /*start*/ addr, /*end*/ addr + len);
      dwfl_report_end(dwfl, NULL, NULL);
    }
}


////////////////////////////////////////////////////////////////////////
// unwind data consumers: basic statistics

UnwindStatsConsumer::~UnwindStatsConsumer()
{
  this->stats->print_summary();
}

void UnwindStatsConsumer::process(const UnwindSample *sample)
{
  /* Most of the logic is handled by UnwindStatsTable.  */
}

int UnwindStatsConsumer::maxframes()
{
  return opt_maxframes >= 0 ? opt_maxframes : 256;
}


////////////////////////////////////////////////////////////////////////
// unwind data consumers: gprof

/* gmon.out file format bits */
#define GMON_MAGIC "gmon"
#define GMON_VERSION 1

struct gmon_hdr {
  char cookie[4];
  char version[4];
  char spare[3 * 4];
};

enum gmon_entry_tag {
  GMON_TAG_TIME_HIST = 0,
  GMON_TAG_CG_ARC = 1,
  GMON_TAG_BB_COUNT = 2,
};

struct gmon_hist_hdr {
  uint8_t tag; /* GMON_TAG_TIME_HIST */
  uint8_t unused[3];
  uint64_t low_pc;
  uint64_t high_pc;
  uint32_t num_buckets;
  uint32_t prof_rate;
  char _dimension_string[16];
};

void GprofUnwindSampleConsumer::record_gmon_hist(ostream &of,
						 map<uint64_t, uint32_t> &histogram,
						 uint64_t low_pc, uint64_t high_pc,
						 uint64_t alignment)
{
  // write one histogram from low_pc ... high_pc
  uint32_t num_buckets = (high_pc-low_pc)/alignment + 1;
  double result_scale = (double)((high_pc-low_pc)/sizeof(uint16_t))/num_buckets;
  if (verbose > 5)
    /* It's the @scale value that must be kept within 0.000001 of 0.5 to
       keep gprof from complaining.  */
    clog << format("DEBUG +hist {:x}..{:x} (alignment {}) of {} buckets @scale {}\n",
		   low_pc, high_pc, alignment, num_buckets, result_scale);

  // write histogram record header
  unsigned char tag = GMON_TAG_TIME_HIST;
  of.write(reinterpret_cast<const char *>(&tag), sizeof(tag));
  int wordsize = (sizeof (void *) == 8) ? 8 : 4;
  if (wordsize == 4) {
    uint32_t addr = low_pc;
    of.write(reinterpret_cast<const char *>(&addr), sizeof(addr));
    addr = high_pc;
    of.write(reinterpret_cast<const char *>(&addr), sizeof(addr));
  } else {
    of.write(reinterpret_cast<const char *>(&low_pc), sizeof(low_pc));
    of.write(reinterpret_cast<const char *>(&high_pc), sizeof(high_pc));
  }
  of.write(reinterpret_cast<const char *>(&num_buckets), sizeof(num_buckets));
  uint32_t prof_rate = attr.sample_freq;
  of.write(reinterpret_cast<const char *>(&prof_rate), sizeof(prof_rate));
  // dimension string is 15 chars long (not null terminated)
  std::string dimension_base = libpfm_event.empty() ? "ticks" :
    libpfm_event.substr(0, 15);
  dimension_base.resize(15, '\0'); // ensure exactly 15 bytes
  of.write(dimension_base.data(), 15);
  // dimension character abbreviation: just take the first char of above
  of.write(dimension_base.data(), 1);

  // write histogram buckets
  uint64_t bucket_addr = low_pc;
  int n_overflows = 0, max_overflows = 5; // limit 'bucket overflow' spam
  for (uint32_t bucket = 0; bucket < num_buckets; bucket++)
    {
      uint16_t count = 0;
      for (auto it = histogram.lower_bound(bucket_addr);
	   it != histogram.upper_bound(bucket_addr+alignment-1);
	   it ++)
	{
	  if (numeric_limits<uint16_t>::max() <= (int) count + (int) it->second)
	    {
	      count = numeric_limits<uint16_t>::max();
	      // XXX: a provisional error message to give a sense of
	      // whether this happens often-enough to do something
	      // more complex, such as adjusting the histogram
	      // granularity:
	      if (n_overflows >= max_overflows) break;
	      n_overflows++;
	      cerr << format("WARNING: histogram bucket overflow at {:x}{}",
			     bucket_addr,
			     n_overflows >= max_overflows ?
			     " (... suppressing further warnings for this histogram)" : "")
		   << endl;
	      break;
	    }
	  count += it->second;
	}
      bucket_addr += alignment;
      of.write(reinterpret_cast<const char *>(&count), sizeof(count));
    }
}

void GprofUnwindSampleConsumer::record_gmon_out(const string& buildid, UnwindModuleStats& m)
{
  string filename = output_dir + "/" + "gmon." + buildid + ".out";
  string exe_symlink_path = output_dir + "/" + "gmon." + buildid + ".exe";
  string json_path = output_dir + "/" + "gmon." + buildid + ".json";

  if (output_force) {
    filesystem::remove(filename);
    filesystem::remove(exe_symlink_path);
    filesystem::remove(json_path);
  }

  string target_path = buildid_to_mainfile[buildid];
  if (target_path != unknown_comm) // skip .exe symlink if there's no path
    if (symlink(target_path.c_str(), exe_symlink_path.c_str()) == -1) {
      // Handle error, e.g., print errno or throw exception
      cerr << format("WARNING: symlink failed: {}\n", strerror(errno));
      // NB: no return needed here; proceed to write out other bits.
      // A smart enough consumer will make do with buildid based executable lookup.
    }

  json_object *metadata = json_object_new_object();
  if (!metadata) {
  json_fail:
    cerr << format("ERROR: json allocation failed: {}\n", strerror(errno));
    return;
  }
  json_object *buildid_js = json_object_new_string(buildid.c_str());
  if (NULL == buildid_js) goto json_fail;
  json_object_object_add(metadata, "buildid", buildid_js);
  if (buildid_to_mainfile.count(buildid) != 0) {
    const string &mainfile = buildid_to_mainfile[buildid];
    json_object *mainfile_js = json_object_new_string(mainfile.c_str());
    if (NULL == mainfile_js) goto json_fail;
    json_object_object_add(metadata, "mainfile", mainfile_js);
  }
  if (buildid_to_debugfile.count(buildid) != 0) {
    const string &debugfile = buildid_to_debugfile[buildid];
    json_object *debugfile_js = json_object_new_string(debugfile.c_str());
    if (NULL == debugfile_js) goto json_fail;
    json_object_object_add(metadata, "debugfile", debugfile_js);
  }
  if (libpfm_event != "") {
    json_object *event_js = json_object_new_string(libpfm_event.c_str());
    if (NULL == event_js) goto json_fail;
    json_object_object_add(metadata, "libpfm-event", event_js);
  }
  if (libpfm_event_decoded != "") {
    json_object *event_js = json_object_new_string(libpfm_event_decoded.c_str());
    if (NULL == event_js) goto json_fail;
    json_object_object_add(metadata, "libpfm-event-decoded", event_js);
  }
  {
    json_object *br_js = json_object_new_boolean(branch_record);
    if (NULL == br_js) goto json_fail;
    json_object_object_add(metadata, "branch-record", br_js);
  }

  const char *metadata_str = json_object_to_json_string(metadata);
  if (!metadata_str) goto json_fail;
  ofstream of_js(json_path);
  of_js << metadata_str;
  of_js.close();
  json_object_put(metadata);

  ofstream of(filename, ios::binary);
  if (!of)
    {
      cerr << format(N_("ERROR: buildid {} -- could not open '{}' for writing\n"), buildid, filename);
      return;
    }

  /* Write gmon header.  It and other headers mostly hold
     native-endian and fixed (or native) bitwidth values.  In
     principle, we should get the bitwidth/endianness from the
     particular executable associated with the buildid.  But, being a
     live profiler, we don't really have to deal with CROSS
     architecture work, and for now can just hard-code the bitwidth to
     match this host program. XXX
  */
  int wordsize = (sizeof(void *) == 8) ? 8 : 4;
  struct gmon_hdr ghdr;
  memcpy(&ghdr.cookie[0], GMON_MAGIC, 4);
  uint32_t version = GMON_VERSION;
  memcpy(&ghdr.version[0], reinterpret_cast<const char *>(&version), 4);
  memset(&ghdr.spare[0], 0, sizeof(ghdr.spare));
  of.write(reinterpret_cast<const char *>(&ghdr), sizeof(ghdr));

  if (m.histogram.size() > 0)
    {
      uint64_t low_pc = m.histogram.begin()->first;
      uint64_t high_pc = m.histogram.rbegin()->first;
      uint64_t alignment = (high_pc - low_pc + 1) / UINT_MAX + 1;

      if (gmon_hist_split == HIST_SPLIT_NONE)
	{
	  /* Put everything into one histogram.  */
	  this->record_gmon_hist(of, m.histogram, low_pc, high_pc, alignment);
	}
      else if (gmon_hist_split == HIST_SPLIT_EVEN)
	{
	  /* This option attempts to satisfy gprof's histogram scale
	     consistency check, which requires all values
	     '(double)(high_pc-low_pc)/num_buckets' to fall within
	     EPSILON.  In practice, we can only be sure of this if we
	     cover the address space with histograms all one size.  */

	  /* Keep the search for 'optimal' size simple -- we just need
	     a plausible order of magnitude.  XXX Some rechecking of
	     correctness needed.  */
	  //uint64_t min_size = 1; // this is 'optimal' much of the time
	  uint64_t min_size = 1024;
	  uint64_t max_size = high_pc - low_pc;
	  uint64_t opt_size = min_size;
	  uint64_t opt_est = 0;
	  uint64_t next_size = opt_size;
	  while (next_size < max_size)
	    {
	      uint64_t size_inc = sizeof(struct gmon_hdr) + next_size;
	      uint64_t size_est = size_inc;
	      uint64_t pc = low_pc;
	      while (pc + size_est < high_pc)
		{
		  auto it = m.histogram.upper_bound(pc + size_est/alignment);
		  if (it == m.histogram.end())
		    break;
		  pc = it->first;
		  size_est += sizeof(struct gmon_hdr) + next_size;
		}
	      if (opt_est == 0 || size_est < opt_est)
		{
		  opt_size = next_size;
		  opt_est = size_est;
		}
	      // if (opt_est > prev_est) break; /* XXX: We've hit the lowest point.  */
	      next_size = 2 * next_size;
	    }

	  /* Partition into histograms of opt_size.
	     TODO: Need to check if low_pc must be aligned.  */
	  uint64_t prev_pc = low_pc;
	  uint64_t pc = prev_pc;
	  for (const auto& p : m.histogram)
	    {
	      pc = p.first;
	      if (pc - low_pc > opt_size)
		{
		  /* Record a histogram from low_pc to low_pc+opt_size.  */
		  this->record_gmon_hist(of, m.histogram,
					 low_pc, low_pc+opt_size-1 /* >= prev_pc */,
					 alignment);
		  low_pc = pc;
		}
	      prev_pc = pc;
	    }
	  /* Record a final histogram from low_pc to low_pc+opt_size.
	     TODO: Edge case -- adjust for overflow of
	     low_pc+opt_size at end of address space.  */
	  this->record_gmon_hist(of, m.histogram,
				 low_pc, low_pc+opt_size-1 /* >= prev_pc */,
				 alignment);
	}
      else if (gmon_hist_split == HIST_SPLIT_FLEX)
	{
	  /* Allow variable-size histograms to save on storage space.
	     Will fail gprof's input consistency checks, XXX but ok
	     for profiledb purposes?  */
	  uint64_t prev_pc = low_pc;
	  uint64_t pc = prev_pc;
	  /* Iterate histogram ascending by key, faster than by addr
	     when we just need to scan for gaps.  */
	  for (const auto& p : m.histogram)
	    {
	      pc = p.first;
	      uint64_t bin_dist = (pc - prev_pc) / alignment;
	      if (bin_dist > sizeof(struct gmon_hist_hdr))
		/* XXX If we add '&& low_pc != prev_pc && pc != high_pc',
		   this avoids producing a histogram with only 1 entry,
		   but this is still not enough to satisfy gprof's
		   histogram scale calculation.  */
		{
		  /* Record a histogram from low_pc to prev_pc.  */
		  this->record_gmon_hist(of, m.histogram, low_pc, prev_pc, alignment);
		  low_pc = pc;
		}
	      prev_pc = pc;
	    }
	  /* Record a final histogram from low_pc to pc.  */
	  this->record_gmon_hist(of, m.histogram, low_pc, pc, alignment);
	}
    }

  /* Write call graph arcs.  */
  for (auto& p : m.callgraph)
    {
      unsigned char tag = GMON_TAG_CG_ARC;
      of.write(reinterpret_cast<const char *>(&tag), sizeof(tag));
      /* p is (from,to) -> count */
      if (wordsize == 4) {
	uint32_t addr = p.first.first;
	of.write(reinterpret_cast<const char *>(&addr), sizeof(addr));
	addr = p.first.second;
	of.write(reinterpret_cast<const char *>(&addr), sizeof(addr));
      } else {
	uint64_t addr = p.first.first;
	of.write(reinterpret_cast<const char *>(&addr), sizeof(addr));
	addr = p.first.second;
	of.write(reinterpret_cast<const char *>(&addr), sizeof(addr));
      }
      uint32_t count = p.second;
      of.write(reinterpret_cast<const char *>(&count), sizeof(count));
    }

  of.close();
}

GprofUnwindSampleConsumer::~GprofUnwindSampleConsumer()
{
  if (show_summary)
    {
      this->stats->print_summary();
      clog << "=== buildid / sample counts ===\n";
    }

  UnwindStatsTable::buildid_map_t sorted_map(this->stats->buildid_tab.begin(), this->stats->buildid_tab.end());
  for (auto& p : sorted_map) // traverse in sorted order
    {
      const string& buildid = p.first;
      UnwindModuleStats& module_stats = p.second;
      this->record_gmon_out(buildid, module_stats);
      if (show_summary)
	{
	  /* In record_gmon_out we will write the buildid->path mapping
	     to a json metadata file.  That makes for a reasonable hint;
	     debuginfod-find can be used as a mostly-functional fallback
	     (for packaged rather than locally-built executables) if the
	     results are moved to another system.  */
	  string mainfile = "<unknown>";
	  if (buildid_to_mainfile.count(buildid) != 0)
	    mainfile = buildid_to_mainfile[buildid];
	  string debugfile = "";
	  if (buildid_to_debugfile.count(buildid) != 0)
	    debugfile = buildid_to_debugfile[buildid];
	  clog << format(N_("buildid {} ({}{}{}) -- received {} distinct pcs, {} callgraph arcs\n"), /* TODO also count samples / estimated histogram size? */
			 buildid,
			 mainfile,
			 debugfile.empty() ? "" : " +debugfile ",
			 debugfile,
			 module_stats.histogram.size(),
			 module_stats.callgraph.size());
	}
    }
  if (show_summary)
    {
      clog << "===\n";
      clog << format(N_("TOTAL -- received {} buildids\n"), this->stats->buildid_tab.size());
    }
  clog << "\n";
}

int GprofUnwindSampleConsumer::maxframes()
{
  // gprof only needs one level of backtracing,
  // but user can override consumer's preference
  // with --maxframes option:
  return opt_maxframes >= 0 ? opt_maxframes : 1;
}

void GprofUnwindSampleConsumer::process(const UnwindSample *sample)
{
  if (sample->addrs.size() < 1)
    return; // edge case -- no pc or callgraph arc

  Dwarf_Addr pc = sample->addrs[0];
  Dwarf_Addr pc2 = sample->addrs.size() < 2 ? 0 : sample->addrs[1];

  Dwfl_Module *mod = dwfl_addrmodule(sample->dwfl, pc);
  if (mod == NULL)
    return;

  Dwfl_Module *mod2 = dwfl_addrmodule(sample->dwfl, pc2);
  // XXX: allowing mod2 == NULL -- callgraph arc will be skipped

  // extract buildid for pc (hit callee)
  const unsigned char *desc = nullptr;
  GElf_Addr vaddr;
  int build_id_len = dwfl_module_build_id(mod, &desc, &vaddr);
  if (build_id_len <= 0)
    return; // TODO: report/tabulate hit outside known modules

  // possible optimization would be to use the unconverted build_id_desc as hash key
  string buildid;
  for (int i = 0; i < build_id_len; ++i) {
    buildid += format("{:02x}", static_cast<int>(desc[i]));
  }

  const char *mainfile_cstr;
  const char *debugfile_cstr;
  Dwarf_Addr low_addr;
  Dwarf_Addr high_addr;
  dwfl_module_info(mod, NULL, &low_addr, &high_addr, NULL,
		   NULL, &mainfile_cstr, &debugfile_cstr);
  string mainfile = mainfile_cstr ? mainfile_cstr : "<unknown>";
  string debugfile = debugfile_cstr ? debugfile_cstr : "";
  if (!buildid_to_mainfile.count(buildid))
    buildid_to_mainfile[buildid] = mainfile;
  if (!buildid_to_debugfile.count(buildid))
    buildid_to_debugfile[buildid] = debugfile;
  // TODO: Also monitor for collisions here.

  UnwindModuleStats *buildid_ent = this->stats->buildid_find_or_create(buildid, mod);

  uint64_t last_pc = pc;
  int i = dwfl_module_relocate_address(mod, &pc);
  /* XXX: Out-of-range address seen with ld-linux.so, not useful for profiledb purposes:  */
  if (last_pc < low_addr || last_pc > high_addr)
    {
      if (verbose)
	clog << format(N_("{}: Skipping pc={:x} raw_pc={:x} outside module range start={:x}..end={:x}\n"),
		       mainfile, pc, last_pc, low_addr, high_addr);
      return;
    }
  (void) i;
  // XXX: could get dwfl_module_relocation_info(mod, i, NULL), but no need?
  buildid_ent->record_pc(pc);

  // If caller & callee are in different modules, this is a cross-shared-library
  // call, so we can't track it as a call-graph arc.  TODO: at least count them
  if (sample->addrs.size() >= 2 && mod == mod2) // intra-module call
    {
      last_pc = pc2;
      int j = dwfl_module_relocate_address(mod, &pc2); // map pc2 also
      if (last_pc < low_addr || last_pc > high_addr)
	{
	  if (verbose)
	    clog << format(N_("{}: Skipping pc={:x} raw_pc={:x} outside module range start={:x}..end={:x}\n"),
			   mainfile, pc2, last_pc, low_addr, high_addr);
	  return;
	}
      (void) j;
      buildid_ent->record_callgraph_arc(pc2, pc);
    }
}
