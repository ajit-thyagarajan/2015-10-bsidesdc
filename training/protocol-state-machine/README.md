
Protocol State Machine
===

Contents
=====

[1. HTTP a Single Request](#http)

[2. Using a BPF to Filter Traffic](#bpf)

[3. More Bro](#morecowbell)

[4. Exercises](#stretch)

[5. A Dramatic Inerpretation of Network Traffic](#thetheater)

<a name="http"></a>
##1. HTTP a Single Request ##
===


Let's confirm we are running using bro 2.4:

```bro -v```


Let's go ahead and walk through a protocol state machine for a single http web request.  Let's start by replaying a pcap through bro and logging all of the events as they fire.  We are going to go ahead and change to the  ```training/protocol-state-machine``` folder and we'll be using the file ```/opt/TrafficSamples/http-partial-content-transfer.pcap``` for this demonstration.


Let's ask Bro tell us about the events that are firing when a pcap is run.

```bro -C -r /opt/TrafficSamples/http-partial-content-transfer.pcap  policy/misc/dump-events.bro```

Whoah.  What was all that?  Let's log that to a file:

```bro -C -r /opt/TrafficSamples/http-partial-content-transfer.pcap  policy/misc/dump-events.bro > dump-events.log```

You should see a download of a file from the host ```54.230.103.187```.  For the purpose of this exercise this will be the host that we are interested in today.

Review the log.  Use your choice of ```less``` or ```less -S``` to have the log scroll down the screen (there is a handy guide on the back of your cheat sheets). 

These logs can get kind of big, let's go ahead and ```rm *.log``` to clear them out.

<a name="bpf"></a>
##2. Using a BPF to Filter Traffic ##
==

There is a lot of other information in the pcap; it's really hard to zoom right in on the specific piece of code that we are looking for.  Have you heard of a Berkeley Packet Filter before?  If not take a minute to read about them.

Bro supports a BPF Capture Filter; let's review Bro's support for them here: [Bro BPF](https://www.bro.org/sphinx/scripts/base/frameworks/packet-filter/main.bro.html?highlight=default_capture_filter#id-PacketFilter::default_capture_filter).

Can you come up with a capture filter that will tell Bro to only show the traffic that we are interested in?  Need some help?  Take a quick look at a [BPF Cheatsheet](http://biot.com/capstats/bpf.html).

Your filter should look something like this:

```bro -C -r /opt/TrafficSamples/http-partial-content-transfer.pcap policy/misc/dump-events.bro "PacketFilter::default_capture_filter = \"YOUR FILTER HERE\""```


You should see a download of a file from the host ```54.230.103.187```.

If you are having trouble figuring out the BPF please let me know; I have also extracted this single flow and extracted it to: ```training/protocol-state-machine/http-single-host-54.230.103.187.pcap```.

<a name="morecowbell"></a>
## 3. More Bro ##
===

Let's look at how we told Bro to run in the previous two exercies:

```bro -C -r http-single-host-54.230.103.187.pcap  policy/misc/dump-events.bro > dump-events.log```

One thing that I notice straight away- we didn't load ```local.bro```!  So none of the scripts, frameworks or framework extensions that would be loaded when Bro runs were not used in this case.

Let's ask Bro to read the traffic sample again except let's load ```local.bro``` and write the output to a different file so that we can compare the two files.


```bro -C -r http-single-host-54.230.103.187.pcap local policy/misc/dump-events.bro > dump-events-local.log```

<a name="stretch"></a>
##4. Exercises ##
===

1. What file is being downloaded?
2. What user-agent is being used?  
3. In what event is this data first available to you in scriptland?
4. Figure out a way to compare the different events being launched in the two versions of your ```dump-events```.
5. Identify at least two events that fire when local is called vs. when local is not called.
6. Identify at least two events that are called the exact same number of times between the two scripts.

<a name="thetheater"></a>
##5. A Dramatic Inerpretation of Network Traffic ##
===

Class Project.  I need two brave volunteers.

*Follow Along:*

1. Using a piece of paper, draw a flow chart of the Protocol State Machine for this transaction
2. Imagine what a PSM would look like for FTP?  IRC?  SSL/TLS?  How are they the same, how are they different?



__Copyright (c) 2015 Critical Stack LLC.  All Rights Reserved.__
