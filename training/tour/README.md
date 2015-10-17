Tour of the Bro Logs
===

Contents
=====

[1. Configuration](#config)

[2. Replaying Traffic with Bro](#replay)

[3. Bro Compared to Wireshark](#wireshark)

[4. It's all about the base](#base)

[5. Enabling Additional Bro Scripts](#scripts)

[6. Policy](#policy)

<a name="config"></a>
1. Configuration
===

Let's start my examining the configuration on our containers so Bro knows what to consider ```local```.

  1. Let's log on as root.
    * ```su -```
    * the password is ```BroTraining4Me```
  2. Let's edit Bro's main configuration file, using the editor of your choice:
    * ```nano -w /opt/bro/share/bro/site/local.bro```
  3. Let's tell Bro what is local (or verify that it is already there); at the bottom of the file let's add:
    * 
```
redef Site::local_nets += {
  192.168.0.0/16,
  10.0.0.0/8,
  172.16.0.0/12,
  100.64.0.0/10,
  127.0.0.0/8,
};
```
  4. Save it; in *nano* you can type CONTROL+O, and then CONTROL+X
  5. Log off as root by type ```exit```

<a name="replay"></a>
2. Replaying Traffic with Bro
===

  1. Start by moving to our test directory:
    * ```cd 2015-10-bsidesdc/training/files-framework``` 
  2. Run Bro against a PCAP: 
    * ```bro -r /opt/TrafficSamples/faf-exercise.pcap```
  3. Look at the logs generated: 
    * ```ls *.log```
  4. Go through some of the logs (e.g. less -S files.log); intro to log guides

<a name="wireshark"></a>
3. Bro compared to Wireshark
===

**We'll do this as a class exercise**

1.  Open **Wireshark** from the desktop and open ```/opt/TrafficSamples/faf-exercise.pcap``` in the window.
2. Right click on **Frame 1** and  go to **Converation Filter** and select **--> TCP**.
3. Let's look at the first line in your Bro ```http.log```; it will look something like this:
```
1258544215.203850       CjVLXK2sVHwin7o6cc      192.168.1.104   1258    77.67.44.206    80      1       GET...
```
4. In the second column you will see the ```uid```; this is the connection unique identifier.  This number is 96-bit integer, an implementation of the GUID and mathematically speaking [1] is probably unique; .  As a side bar, this used to be a 64-bit integer [2] until someone from a small nordic country complained about collisions.  If you're curious you can easily calculate the birthday problem [3] on various numbers of connections [4].
5. Let's take that ``uid`` (what ever **yours** is) and let's have a piece of yummy bro cake:
```
grep -rin CjVLXK2sVHwin7o6cc ./ | less -S
```
6. Explore each log line to understand the context?

**Questions**

1. How many packets are summarized by Bro? 
2. How many layers of cake do you see for the first HTTP Connection?
3. What logical layers are represented in the logs generated for the first layer of traffic?
4. Generate a quick listing of all of the logs generated so they stay in your shell history buffer: ``` ls *.log```


   * [1] http://en.wikipedia.org/wiki/Globally_unique_identifier
   * [2] https://bro-tracker.atlassian.net/browse/BIT-1016
   * [3] http://en.wikipedia.org/wiki/Birthday_problem
   * [4] http://preshing.com/20110504/hash-collision-probabilities/

<a name="base"></a>
4. It's all about the base
===

Above when we ran bro we ran it in **base** mode.  This means that Bro loaded all of the built in scripts that you find in the directory ```/opt/bro/share/bro/base```

```
~/2015-10-bsidesdc/training/files-framework >  ls /opt/bro/share/bro/base
bif  files  frameworks  init-bare.bro  init-default.bro  misc  protocols  utils
```

For the last 20 years, when people have thought about *what bro is* or *what bro does* they generally are thinking about **base**.  These are the default scripts that generate the most basic output of Bro.  Let's explore these three categories a bit to understand the **base** of Bro.

**protocols**
==

Let's begin by exploring the ```protocols``` directory:

```
ls /opt/bro/share/bro/base/protocols/
conn  dhcp  dnp3  dns  ftp  http  irc  modbus  pop3  radius  smtp  snmp  socks  ssh  ssl  syslog  tunnels
```

Here we see a folder for *most* of the protocols that Bro supports out of the box.  Let's take a look at one of these, **http**.

```
ls /opt/bro/share/bro/base/protocols/http/
dpd.sig  entities.bro  files.bro  __load__.bro  main.bro  utils.bro
```

Using **http** as an example, most protocols will follow this basic template:

1.  **__load__.bro** : This file is just a recursive loader; if you ever tell Bro to load a directory it will look for this file and then recursively load the contents.
2.  **main.bro** : this file sets up the default ```http.log``` you may be familiar with- find it on your cheatsheets.  It also adds some VERY important template structures to the underlying ```c: connection``` record that is used to track the connection through time.  We'll explore this more later.
3.  **entities.bro** : this script directs and analyzes http mime entities as they are communicated by connection *originators* and connection *responders*.  Think header entities and body entities.
4.  **utils.bro** : this file loads a bunch of *http* specific files for parsing, processing and understanding the semantics of the http protocol.
5.  **files.bro** : these are helper scripts for proper file handling and reassembly in bro
6.  **dpd.sig** : this file includes the signatures that are used to enable a protocol parser on a specific connection.

Not every protocol has all of these components, however they are generally similar to this.

**frameworks**
==

In a similar fashion let's explore the ```policy``` directory.

```
/opt/bro/share/bro/base/frameworks > ls
analyzer  communication  dpd    input  logging  packet-filter  signatures  sumstats
cluster   control        files  intel  notice   reporter       software    tunnels
```

Here we see much of the core functionality that provides higher level logs and models with in Bro.  *Frameworks* in bro are somewhat analogous to *libraries* in other languages.

With even a superficial glance we find a similar design patter to what we found in the ```protocols``` folder.  Each framework has a recursive ```__load__.bro```, a ```main.bro``` defining core functionality and perhaps some helper utilities.  Go ahead and peek at a few:

```
/opt/bro/share/bro/base/frameworks > ls tunnels/
__load__.bro  main.bro
/opt/bro/share/bro/base/frameworks > ls files/
__load__.bro  magic  main.bro
/opt/bro/share/bro/base/frameworks > ls control/
__load__.bro  main.bro
/opt/bro/share/bro/base/frameworks > ls software/
__load__.bro  main.bro
```

**bif: Built In Functions**
==

The ```bif``` directory contains the functions that are accessible as calls using the Bro Programming Language however are implemented in the core in C++.  Generally you find here a collection of events & functions that are not particularly associated with any one connection.

```
/opt/bro/share/bro/base > ls bif
analyzer.bif.bro      broxygen.bif.bro             event.bif.bro          __load__.bro     reporter.bif.bro  types.bif.bro
bloom-filter.bif.bro  cardinality-counter.bif.bro  file_analysis.bif.bro  logging.bif.bro  strings.bif.bro
bro.bif.bro           const.bif.bro                input.bif.bro          plugins          top-k.bif.bro
```

A few of the more important ones:

1. **const.bif.bro** : Declaration of various scripting-layer constants that the Bro core uses internally. Documentation and default values for the scripting-layer variables themselves are found in base/init-bare.bro.
2. **types.bif.bro** : Declaration of various types that the Bro core uses internally.
3. **strings.bif.bro** : Definitions of built-in functions related to string processing and manipulation.
4. **bro.bif.bro** : A collection of built-in functions that implement a variety of things such as general programming algorithms, string processing, math functions, introspection, type conversion, file/directory manipulation, packet filtering, interprocess communication and controlling protocol analyzer behavior.
5. **base/bif/event.bif.bro** : The protocol-independent events that the C/C++ core of Bro can generate.  This is mostly events not related to a specific transport- or application-layer protocol, but also includes a few that may be generated by more than one protocols analyzer (like events generated by both UDP and TCP analysis.)

**utils**
==

The ```utils``` folder contains helpful functions that you can leverage in your bro scripts.  These helper functions include scripts to help you dynamically determine the locality and directionality of a connection.  We will explore these at the end of the week as we dive into programming.

```
/opt/bro/share/bro/base > ls utils/
active-http.bro  conn-ids.bro  directions-and-hosts.bro  files.bro    paths.bro     queue.bro  strings.bro     time.bro
addrs.bro        dir.bro       exec.bro                  numbers.bro  patterns.bro  site.bro   thresholds.bro  urls.bro
```

It is important to note, that unlike  ```bif```'s most of the functions implemented in the ```utils``` directory are implemented using the Bro programming language, meaning that they are going to be relatively slower and less efficient.

There are some notable utilities in here though:

1.  **active-http.bro** : an interface to use *curl*
2.  **directions-and-hosts.bro** : functions to help you develop around the directionality and locality of a connection.
3.  **urls.bro** : extract urls from a string

**files**
==

The files section of base really hints towards the future of Bro- the language about bro being a network programming language or a network stream processor has been deliberately purged from the literature.  These are file protocol analyzers- we'll dive into them more later however they are:

1. extract
2. **hash** : Hash all the things
3. **unified2** : snort / suricata unified2 format
4. **x509** : SSL/TLS Certificate Analyzer


<a name="scripts"></a>
5. Enabling Additional Bro Scripts
===

1. Let's replay that traffic sample again this time asking Bro to enable some additional scripts: 
    * ```bro -r /opt/TrafficSamples/faf-exercise.pcap local```
2. Comparing your history, what additional logs are generated?
```
~/2015-10-bsidesdc/training/files-framework > ls *.log
conn.log  files.log  ftp.log  http.log  packet_filter.log  smtp.log  ssl.log  x509.log
~/2015-10-bsidesdc/training/files-framework > bro -r /opt/TrafficSamples/faf-exercise.pcap local
~/2015-10-bsidesdc/training/files-framework > ls *.log
conn.log   ftp.log   known_certs.log  known_services.log  notice.log         smtp.log      ssl.log
files.log  http.log  known_hosts.log  loaded_scripts.log  packet_filter.log  software.log  x509.log
~/2015-10-bsidesdc/training/files-framework > 
```
3. You should see an additional set of logs generated; not only that however if you were to look closely you would notice that the contents of some of the logs have changed.
4. When you tell Bro to also load ```local``` Bro knows to where to find this script- it knows where it lives.  Explore the configuration: 
    * ```less -S /opt/bro/share/bro/site/local.bro```
    * The Training VMs [local.bro](https://github.com/criticalstack/2015-10-bsidesdc/blob/master/misc/local.bro)
5. Please examine:
   * ```known_certs.log```
   * ```known_hosts.log```
   * ```notice.log```

<a name="policy"></a>
6. Policy
===

When examining ```local.bro``` in the previous step you may have noticed a lot of additional scripts being loaded.  By default Bro is shipped very policy neutral- base doesn't really tell you much beyond trying to log the ground truth of what happened in a given protocol.  There is a lot of additional analysis and context that can be gained by loading scripts as a matter of your organizations *policy*.  Hence the name for the collection of additional bro scripts, framework extensions and so forth: ```/opt/bro/share/bro/policy```.

If we look at the structure and layout for this folder, we'll find that it pretty directly mirrors what we found in the base directory:

1. **frameworks** : extensions and plugins to the frameworks defined in Bro. 
2. **integration** : integration with both barnyard2 and the collective intel server (if)
3. **misc** : scripts with no better home.  *scan.bro*, *dump-events.bro*, *profiling.bro*, and more.
4. **protocols** : protocol specific scripts and extensions.
5. **tuning** : scripts that perform a variety of reconfiguration of Bro.

**Exercises:**
==

1. After replaying Bro using the ```local``` keyword   a new log ```notice.log``` was generated.  Examine the output of the lines- can you find the script that generated this alert?
2. Can you do the same for ```known_hosts.log```?
3. How about ```known_services.log```
