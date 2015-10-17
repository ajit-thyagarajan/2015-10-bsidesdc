Files Framework Contents
=====
[0. Files Framework Overview](#overview)

[1. Files Framework State Machine](#filefsm)

[2. Mime Types](#mimetype)

[3. Streaming File Analyzers](#analyzers)

[4. Mo' MIMEs, Mo' Problems](#toomanymimes)

[5. Conditionally Enabling File Analyzers](#condanalyze)



<a name="overview"></a>
## 0. File Framework Overview ##
===

The Files Framework is one of the most innovative components integrated into Bro today.  The model revolves around identifying, analyzing, and logging files in a **streaming** piecewise fashion.  This is very similar to how connections are analyzed in Bro; a protocol has a protocol state machine, a defined pattern of behavior, and so do files.  Many of the next major innovations in Bro itself will revolve around an extended and streaming analysis of Files.

The Files Framework consists of 3 main parts:

1. The Files Framework itself
2. A library used to identify the mime types of files
3. Streaming File Analyzers that may be attached to files in order to analyze or operate on them

The files framework itself is located at ```<PREFIX>/bro/share/bro/base/frameworks/files``` and consists of a ```main.bro``` and a library of file mime type signatures located under the ```magic``` directory.  The framework itself will generate the ```files.log``` that provides a *protocol agnostic* log for files.  When we speak of a *protocol agnostic* source for files we are really saying that this log contains information about all of the files regardless of their source.  Files may be transferred over network protocols as content, transferred with in the protocol itself, may come from other files or may even be read in from disk.

**Files transferred by Protocol Analyzers**

You are probably most familiar with he first case of files- that there are many protocols that transfer files as a specific component of their function; consider the following examples:

* **HTTP** is used by web browsers and other tools to download HTML files, pictures, flash content and more for display in your browser.  It is worth noting that HTTP is also heavily leveraged as a protocol for developers leveraging REST based API's transferring files formatted as JSON, XML, CSV or other types of files.
* **FTP** is another protocol heavily used to transfer files.
* **SMTP** is used to transfer both files as email messages and separately their attachments.

It is worth noting that there are some significant differences between the **way** these protocols transfer files.  For example in the *HTTP Protocol* state machine one may use a special *HTTP Header* in order to indicate the file name, however this is commonly not performed.  The result is that typically files transferred via HTTP do not have the filename column set in the ```files.log```.  However with SMTP and FTP based file transfers attachments and FTP targets are typically named.  

For an in depth discussion on the best practices for setting filenames using HTTP Headers please refer to [RFC2383](https://tools.ietf.org/html/rfc2183) and the wikipedia article on [MIME](https://en.wikipedia.org/wiki/MIME).


**Files transferred as a component of Protocol Analyzers**

There are are other protocols that transfer files as a component of their *protocol state machine*.  These files are often leveraged by the protocols themselves in order to define how the protocol may behave.  The most common example of this are **X509 Certicate** files seen in both the SSL and TLS protocols.

In the SSL and TLS protocols use X509 Certicates to validate both the identity of an organization and to define they specific types of encryption to be used during a session.

**Other Sources of Files**

Files of course may come from other files- many common document types are either designed specifically to transport other files or include mechanisms for their inclusion.  There are many types of Archive files such as ```zip```, ```rar```, and ```tar``` that bundle up other files.  Both Microsoft office files and PDF files include native mechanisms for embedding content, files, inside of them.

Bro also supports a mechanism to load or read files in right from disk; while this feature is not commonly used one can imagine creating IR scripts or using Bro at the terminal in realtime to kick off an IR workflow.

As an aside, in regards to security, there are many file formats that are include scripting languages that may be used to dynamically create files on the fly- for example, consider an excel document that uses vbscript to create a file on the fly.  Files such as these are dependent on the script itself being executed and *may* not simply be extracted by examine the contents of the files.


<a name="filefsm"></a>
## 1. Files Framework State Machine ##
===

Let's start by examine a simple file download:

```
bro -r simple-image-download.pcap policy/misc/dump-events.bro > dump.txt
```

1. Examine ```files.log```, how many files were downloaded?
2. How many connections were used to download this file?
3. What is the mime type of the file?
4. Examine the ```dump.txt``` you created- what are the events we see generated from the files framework?  (Hint 1)  Sketch a *file state machine* showing the phases that a file transitions through when downloaded.

[Exercise 1.4 Hint](#e1d4)



<a name="mimetype"></a>
## 2. Mime Types ##
===

The Bro files framework includes a large library of mime types signatures that may be used to dynamically determine the mime type of a file.  The Bro mime type signatures leverage the same signature framework utilized by the Dynamic Protocol Detection (DPD), for example to detect PDF files:

```
# >0  string,=%PDF- (len=5), ["PDF document"], swap_endian=0
signature file-magic-auto189 {
        file-mime "application/pdf", 80
        file-magic /(\x25PDF\x2d)/
}
```

You can locate the signatures for mime types at ```<PREFIX>/bro/share/bro/base/frameworks/files/magic```.  Examining this directory shows us that there are 379 signatures organized into many different categories:

* **archive.sig**: 29 signatures for archive type of files such as zip, rar, and tar
* **audio.sig**: 2 signatures for audio files
* **font.sig**: 7 signatures for types of font files
* **general.sig**: includes 50 signatures for a wide variety of files including HTML, son, and XML files.
* **image.sig**: has 29 signatures for a different image formats
* **libmagic.sig**: 240 different file signatures curated from a conversion from the version 5.17 libmagic database.
* **msoffice.sig**: Contains 6 different signatures for office document files.
* **video.sig**: includes 16 signatures for video related files such as MPEG, H.264 and Flash files

In the file state machine Bro gives you insight into file metadata with the ```file_sniff``` event:

```
event file_sniff(f: fa_file, meta: fa_metadata)
```

At this time you receive all of the metadata about a particular file from the inspection of the *initial* content that has been seen at the beginning of the file.  At this time you can choose to enable or disable other analyzers using the function ```Files::add_analyzer```.

Let's explore this peek into the files.

1. Create an empty file call sniff.bro

**sniff.bro**

```
event file_sniff(f: fa_file, meta: fa_metadata)
{
 print meta;
}
```

Tell Bro to examine the pcap using your new script:
```
bro -r ../1-simple-download/simple-image-download.pcap sniff.bro
[mime_type=image/png, mime_types=[[strength=110, mime=image/png]]]
```

2. What is the mime type of the file?
3. Locate the  ```file_sniff``` event in the Bro Manual 

<a name="analyzers"></a>
## 3. Streaming File Analyzers ##
===

Bro is not just interface with *network protocols*; it ships today with a handful of *Streaming File Analyzers* that may be used to inspect, extract and generate metadata from the files themselves.

Located at ```<PREFIX>/bro/share/bro/base/files``` Bro 2.4 includes:


* **Files::ANALYZER_DATA_EVENT**: this analyzer may be used to connect the output of a file to a script; useful for a quick analysis or custom meta data extraction (caveat: script land is slow)
* **Files::ANALYZER_EXTRACT**: this analyzer can be used to extract files to a location on disk
* **Files::ANALYZER_MD5**: generates the MD5 hash of a file
* **Files::ANALYZER_PE**: analyzes the PE header of DOS executables and extracts metadata to pe.log
* **Files::ANALYZER_SHA1**: generates the SHA1 hash of a file
* **Files::ANALYZER_SHA256**: generates the SHA256 hash of a file
* **Files::ANALYZER_UNIFIED2**: this analyzer will read in and parse Snort or Suricate unified2 files, throwing events in Bro when new alerts are written
* **Files::ANALYZER_X509**: this analyzer will inspect, validate and extract 

You can enable these files in one of two ways; you can manually enable them using the function ```Files::add_analyzer``` or you can leverage an internal abstraction to conditionally enable file analyzers based on their mime type.

1. Let's create a script and *extract all the things*.

**extract-all-the-things.bro**

```
@load base/files/extract

event file_new(f: fa_file)
	{
	Files::add_analyzer(f, Files::ANALYZER_EXTRACT);
	}
```

Let's replay a traffic sample against our file:

```
bro -r /opt/TrafficSamples/file-exercise-downloads.pcap extract-all-the-things-solution.bro
```

A new directory should be created in your local directory:

```
3-file-analyzers liamrandall$ ls
conn.log                            extract_files                       http.log
extract-all-the-things-solution.bro files.log                           packet_filter.log
extract-all-the-things.bro          ftp.log                             pe.log
```

Change into the **extract_files** directory and cat out a few of the files.

2. How many files were extracted?
3. What are their mime types?  Where did you look to discover this?  [Exercise 3.3 Hint](#e3d3)
4. Using the above as a template, create a new script called **hash-all-the-things.bro** that enables the SHA1 analyzer and replay it against the same traffic sample?
5. What additional metadata has been added to ```files.log```?  What do you find in the **analyzers** column?
6. Modify your **hash-all-the-things.bro** to enable the SHA1, MD5 and SHA256 Analyzer.  Replay it against the traffic sample and now inspect ```files.log```.

<a name="toomanymimes"></a>
## 4. Mo' MIMEs, Mo' Problems ##
===

In the previous exercises we enabled file analyzers for all of the files with a simple command.  In this exercise we are going to review two techniques for the conditional analysis of file.  We will also begin to understand the conceptional problem inherent in the design of mime types.

**Mime Types: Flawed by design**

There is a tremendous problem with the way that all systems identify and parse files- mime types are flawed by design.  Look back to our signature we introduced that was used to identify a sample file:

```
# >0  string,=%PDF- (len=5), ["PDF document"], swap_endian=0
signature file-magic-auto189 {
        file-mime "application/pdf", 80
        file-magic /(\x25PDF\x2d)/
}
```

Files are essentially identified by a set of *magic bytes* that are used to indicate that a file is of a certain type.  However, over the decades as organizations invented and standardized new file types there was no central organization or set of rules to enforce best practices.  In short, this means that organizations can and **have** placed their magic bytes all over the place- and not in a consistent format.  The *result* is that truly identifying the contents of a file are far less straight forward than it should be in reality.  

What this means in practice is that a single file may actually match *multiple signatures*!  These so called **FRANKENFILES** can and are used quite regularly to serepticously hide, move and transfer data.

Let's use our **sniff.bro** to analyze a larger traffic sample:

```
bro -r /opt/TrafficSamples/file-exercise-downloads.pcap sniff.bro
```

And right here in the first line of the output:

```
[mime_type=text/html, mime_types=[[strength=100, mime=text/html], [strength=49, mime=text/html], [strength=-20, mime=text/plain]]]
```

And this is the entire reason that starting in Bro 2.4 universal standard for mime type analysis and implemented its own logic.  Here we see that the files framework has been designed to tell you about all of the possible matches while simultaneously telling you about the best guess for the mime type.

**Scripting Logic**

Much of Bro's underlying flexibility comes from the having a high level turning complete programming language attached to file analyzers.  In this exercise we are going to being with our template of **sniff.bro** and modify it one small piece at a time in order to turn it into a script that checks the mime type of each file and only enables the extraction analyzer if the file is a DOS executable.

1. Records are types of variables that contain other variables; as an analogy think about putting envelopes in envelops.  In our sniff.bro we are print a record straight to the output and we can see the entire formatted record:

```
print meta;
```

yields:

```
[mime_type=text/html, mime_types=[[strength=100, mime=text/html], [strength=49, mime=text/html], [strength=-20, mime=text/plain]]]
```

Here we can see both the *names* and the *values* of the records.  If we want to access a sub-record we can use the *dereference operator* of *$* to access the contents.  So if we wanted to only print the mime type for each file we would simply: ```print meta$mime_type```.

Modify your script and validate that it works by replaying the cap.

2. Bro has conditional operators that we can leverage to test for equivalence; let's modify our script so that we check to see if the mime type is ```application/x-dosexec```.  We test for equivalence with the double equal sign operator ```==```; when we have found an executable on the next line simply notify the operator with something like ```print "found a windows executable.";``` (don't forget the semicolon!)

3. Now let's replace the print statement by adding the extraction analyzer as in a previous exercise.

4. Replay the script and then verify that you are successfully extracting files.

<a name="condanalyze"></a>

## 5. Conditionally Enabling File Analyzers ##

In the last exercise we selectively enabled the extraction analyzer for a DOS executable. The scripting logic presented is very powerful and allows for some great flexibility. However, it is a pretty common use case that we want to enable certain analyzers for certain file types. The PE analyzer is a great example. It wouldn't make sense to run the PE analyzer on ```text/html``` mime_types.

Instead of creating complex logic in the ```file_new``` event, Bro 2.4 provides a way to generically add sets of MIME types to a given analyzer. First, we can view all the currently associated MIME types by analyzer by creating a bro script called *analyze_by_mime.bro*

**analyze_by_mime.bro**

```
print Files::all_registered_mime_types();
```

Just running this through bro will yield our result:

```
bro analyze_by_mime.bro
```

You should notice an empty set of brackets. This indicates that no mime types have been registered to an analyzer in the base policy. We can create sets of mime types to associate with each one. Let's ask bro to extract all PDF files and run the new PE analyzer on all DOS executables.


**analyze_by_mime.bro**

```
print Files::all_registered_mime_types();
print "=== Before Adding Types ===";
const pdf_mime_types = { "application/pdf" };
const pe_mime_types = { "application/x-dosexec" };
Files::register_for_mime_types(Files::ANALYZER_EXTRACT, pdf_mime_types);
Files::register_for_mime_types(Files::ANALYZER_PE, pe_mime_types);
print Files::all_registered_mime_types();
```

Running just bro against this script will show the same empty set before adding the new types. After we register analyzers for the new MIME types, we see everything we just registered, grouped by MIME type. Executing this against a PCAP that has a PDF and/or a PE file (DOS executable) will result in the repsective analyzers being run.

> **NOTE**: In Bro 2.4, some analyzers will run by default based upon the MIME type. An example is the PE analyzer. Even without the above script, the `pe.log` will be created. This can be turned off, if desired, by redefining the setting `Files::analyze_by_mime_type_automatically` to F.


##Hints##

<a name="e1d4"></a>
####Exercise 1.4 Hint ####

Bro generally utilizes a naming convention for filenames.  Try filtering your pcap by the ```file_``` piece: ```cat dump.txt | grep file_ | less -S```

<a name="e3d3"></a>
####Exercise 3.3 Hint ####

A few easy ways to validate the mime types of the files:

1. Manually use ```files.log```; does this scale?
2. Script it out of ```files.log```:

```
cat files.log | bro-cut mime_type | sort | uniq -c | sort -n
   1 application/x-gzip
   2 application/x-dosexec
   4 text/html
```

3. Changing into the ```extract_files``` directory and leveraging a libmagic based command:

```
file *
extract-1400463871.113072-HTTP-FkIZSq1HSiN5Zjj7y2:     HTML document, ASCII text
extract-1400463871.282616-HTTP-FSSyir2Hb08v9oaQal:     PE32 executable (GUI) Intel 80386, for MS Windows
extract-1400463884.044456-HTTP-FxWMV81IeOMj90Tzvi:     HTML document, ASCII text
extract-1400463886.449325-HTTP-FraUrb3V21HTzGVDz9:     HTML document, ASCII text
extract-1400463917.776036-FTP_DATA-F7TJXt2sgxDLkxUGUh: PE32 executable (GUI) Intel 80386, for MS Windows
extract-1400465331.809379-HTTP-F0BYCI18hrfdCu0Xba:     HTML document, ASCII text
extract-1400465332.030731-HTTP-FADuML2NFHnELsuFQi:     gzip compressed data, last modified: Tue Aug  6 11:12:13 2013, from Unix
```


__Copyright (c) 2015 Critical Stack LLC.  All Rights Reserved.__
