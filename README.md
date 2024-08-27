# ConMAn: Concurrency Mutation Analysis

## What is ConMAn?

The ConMAn (Concurrency Mutation Analysis) operators were developed for mutating concurrent source code written in Java (J2SE 5.0). Each operator is implemented in [TXL](https://www.txl.ca) - a source transformation language. There are 24 ConMAn operators and each operator is based on real concurrency bug patterns:

* MXT – Modify Method-X Time (where X is wait(), sleep(), join(), and await())
* MSP - Modify Synchronized Block Parameter
* ESP - Exchange Synchronized Block Parameters
* MSF - Modify Semaphore Fairness
* MXC - Modify Permit Count in Semaphore and Modify Thread
* MBR - Modify Barrier Runnable Parameter
* RTXC – Remove Thread Method-X Call (where X is wait(), join(), sleep(), yield(), notify(), notifyAll())
* RCXC – Remove Concurrency Mechanism Method-X Call (where X is any method in Locks, Semaphores, Latches, Barriers, etc.)
* RNA - Replace NotifyAll() with Notify()
* RJS - Replace Join() with Sleep()
* ELPA - Exchange Lock/Permit Acquisition
* EAN - Exchange Atomic Call with Non-Atomic
* ASTK – Add Static Keyword to Method
* RSTK – Remove Static Keyword from Method
* ASK - Add Synchronized Keyword to Method
* RSK - Remove Synchronized Keyword from Method
* RSB - Remove Synchronized Block
* RVK - Remove Volatile Keyword
* RFU - Remove Finally Around Unlock
* RXO - Replace One Concurrency Mechanism-X with Another (where X is Locks, Semaphores, etc.)
* EELO - Exchange Explicit Lock Objects
* SHCR - Shift Critical Region
* SKCR - Shrink Critical Region
* EXCR – Expand Critical Region
* SPCR - Split Critical Region

The ConMAn operators can be be used in the comparison of different test suites and testing strategies for concurrent Java as well as different fault detection techniques for concurrency. Although ConMAn has been used previously as a comparative metric for different fault detection tools we believe that these operators can also serve a role similar to method and class level mutation operators as both comparative metrics and coverage criteria. Furthermore, the ConMAn operators should be viewed as a complement not a replacement for the existing operators used in tools like MuJava. For example, using the ConMAn operators can direct mutate concurrency mechanisms like synchronization while using the method level operators can mutate other parts of the source code that may indirectly affect concurrency mechanisms.

## Downloading and Installing ConMAn

The ConMAn Operators are free for download and are distributed under the MIT license. The first step to getting ConMAn setup is download the the [TXL](https://www.txl.ca) compiler/interpreter. The next step is to download the mutation operator source files directly from this repository. 

## Running ConMAn

Each ConMAn Operator can be run separately using the following command:

`txl <infilename> <operator>.Txl - -outfile <outfilename> -outdir <outputpath>`
