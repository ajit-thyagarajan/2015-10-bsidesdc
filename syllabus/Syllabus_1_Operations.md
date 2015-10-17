Day 1- Bro Overview for Operations
===

[0. Virtual Bro Environment](#virtualbro)

[1. Git- Bro Community Co-ordination](#git)

[2. Tour of the Virtual Machines](#tour)

[3. What is Bro](#what)

[4. A Tour of the Bro logs](#tour)

[5. Exploring Logs with bro-cut](#explore)

[6. Protocol State Machine](#statemachine)

[7. Files Framework](#files)

<a name="virtualbro"></a>
0. Virtual Bro Environment
===
*15 Minutes*

  1. Let's get connected the Virtual training environment
    * Open a Terminal, Command Window or other SSH client, such as Putty.
    * logon to our training host using the following details:
      * Host: *t2.criticalstack.com*
      * User: **training**
      * Password: **training**
    * so from a linux or mac based terminal you might type:
      * ```ssh training@t2.criticalstack.com```
    * Walk through the wizard to create your Bro training container
      * There are many like it, but this one is yours- remember your username / password
      * To access this in the future you will use the username / password combo created now


<a name="git"></a>
1. Git- Bro Community Co-ordination
===
*5 minutes*

  1. Mail your github ID to Liam Randall at [training@CriticalStack.com](training@criticalstack.com)
  2. You will recieve an email when you have been added to this repository
  3. Accept the email link
  4. On your remote bro environment, clone the repository: ```git clone https://github.com/criticalstack/2015-10-bsidesdc.git```
  5. You will be prompted for you *github* userid and password to synch the repo down.


<a name="tour"></a>
2. Tour of the Virtual Machines
===
*5 minutes*

  1. Your home directory:
    * ```/home/training/```
  2. Our class files (to be added in the next step)
    * ```/home/training/2015-10-bsidesdc```
  2. Bro installation directory:
    * ```/opt/bro```
  3. Bro's Master Configuration:
    * ```/opt/bro/share/bro/site/local.bro```
  4. Pcaps used in class
    * ```/opt/TrafficSamples/```
    * ```/opt/PCAPS_TRAFFIC_PATTERNS/```

<a name="what"></a>
3. What is Bro
===
*30 minutes*

Let's set the stage for what we are going to try and cover this week in with Bro.

  1. Bro is a language first
  2. Event-driven
  3. Built-in variables like IP address and time interval are designed for network analysis
  4. Built-in functions can be implemented in C++ for speed and integration with other tools
  5. [Presentation: Bro Overview](https://github.com/criticalstack/2015-10-bsidesdc/blob/master/presentations/2014-7-Critical-Stack-Bro-Overview.pdf)
  6. Walk through of the laminated cheat sheets
 
<a name="tour"></a>
4. A Tour of the Bro logs
===
*60 minutes*

Bro is typically run in one of two ways- either as a daemon attached to an interface(s) or at the command line with pcaps.  This week we wills spend the majority of our time replaying targeted traffic samples at the command line; this allows us to focus on specific scenarios.

Let's get started with a [Tour of the Bro Logs](https://github.com/criticalstack/2015-10-bsidesdc/blob/master/training/tour/README.md)

<a name="explore"></a>
5. Exploring Logs with bro-cut
===
*20 minutes*

  1. Let's move into a different set of pcaps
    * ```cd ..training/http-auth```
  2. Exercise:
    * ```bro -C -r /exercises/TrafficSamples/http-basic-auth-multiple-failures.pcap local```
  3. ```bro-cut``` can be used like ```sed```, ```cut```, ```awk``` all at once- with the advantage that it abstracts away from the specific schema (column order) of the logs.
  4. We can easily start to ask questions like: What is the count of the distinct status_code:
    * ```cat http.log | bro-cut status_code | sort | uniq -c | sort -n```
  5. Or you could get a count of http sessions by username:
    * ```cat http.log | bro-cut username | sort | uniq -c | sort -n```
  6. Can you generate a count of status_codes by username? What about usernames by status_code?
  7. Now add in the distinct URI?  What do you think is going on in this pcap?
  8. Let's add a little more information and context to this pcap; let's tell Bro to extract the passwords as well:
    * ```bro -C -r /exercises/TrafficSamples/http-basic-auth-multiple-failures.pcap local http-auth-passwords.bro```
  9. Now let's explore the basic http.log again:
    * ```less -S http.log```
  10. Do you see the populated ```password``` field?
  11. Will the ```bro-cut``` summaries you generated earlier still work?

**Review**

  1. When running bro from the command line you can change the configuration by telling bro to also load different configuration files.
  2. The logs that bro writes are not statically defined; they are the living dynamic output.
  3. There are many ways to manipulate bro logs.

<a name="statemachine"></a>
6. Protocol State Machine
===
*60 minutes*

Bro is different by design.

From the ground up Bro simply approaches problems with a different point of view.  The Bro Platform provides an interface to network traffic through the idea of an event.  That is to say Bro will let you know when certain things happen on the network; there are connection specific events, protocol specific events, framework associated events, time based events, or even your own custom events.

Some sample events are things like:
* ```event bro_script_loaded(path: string, level:count)```
* ```event new_connection(c: connection)```
* ```event file_over_new_connection(f: fa_file, c: connection, is_orig: bool)```

*Each* event can be hooked **zero** or more times based on any number of properties.  Let's try to understand this a little better by exploring **ALL** of the events that fire during a simple HTTP transfer.

[Protocol State Machine Exercises](https://github.com/criticalstack/2015-10-bsidesdc/blob/master/training/protocol-state-machine/README.md)


<a name="files"></a>
7. Files Framework
===
*60 minutes*

The Bro Platform is all about abstracting down to the base case.  One of more novel and powerful abstractions is the files framework- a *protocol agnostic* way of thinking about files in your network.  The files framework gives operators the powerful ability to think about, apply policies to, monitor or react to files on their networks.

[Files Framework Presentation](https://github.com/criticalstack/2015-10-bsidesdc/blob/master/presentations/2014-7-Critical-Stack-files-framework.pdf)

Let's jump out to a seperate set of exercises for the files framework: [File Framework Exercises](https://github.com/criticalstack/2015-10-bsidesdc/blob/master/training/files-framework/README.md)



__Copyright (c) 2015 Critical Stack LLC.  All Rights Reserved.__
