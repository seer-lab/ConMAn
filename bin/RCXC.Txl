%***********************************************************
% RCXC (Remove Concurrency Mechanism Method-X Call) Mutator
% Jeremy S. Bradbury

% Copyright 2006-2007 J.S. Bradbury

% Revision history:

% Description: 
% This operator will remove the occurrence of the following methods
% lock, unlock, signal, signalAll, acquire, release, countDown, submit.

% Future work:
% Currently the implementation removes any occurrence of the above methods and
% does not check the type of object associated with the method. In the future we 
% plan to check the type of object (e.g., check that the acquire method is associated
% with a semaphore.
%***********************************************************

% Base grammar, and grammar override files
include "Java.Grm"
include "JavaCommentOverrides.Grm"

% Local grammar overrides
redefine expression_statement
    		[attr labelM] [expression] ';        [NL]
	|	[attr labelM] '; /* 'MUTANT: [stringlit] */ [NL]		
end redefine

define labelM
	'MUTATED
end define

redefine dot_id
		'. [thread_id]
    	|	'. [id]
end redefine

define thread_id
		'lock
	|	'unlock
	|	'signal
	|	'signalAll
	|	'acquire
	|	'release
	|	'countDown
	|	'submit
end define

%------------------------------------------------------------
% Main rule, followed by other rules in topological order
%------------------------------------------------------------
function main
	% initialize and export a mutant count that will be used in 
	% file name / folder name generation
    	construct MutantCount [number]
		0
    	export MutantCount

	% initialize and export the name of the current mutant which 
	% will be used for folder name generation
	construct MutantOpName [stringlit]
		"RCXC"
	export MutantOpName

	construct Lock [thread_id]
		'lock
	construct Unlock [thread_id]
		'unlock
	construct Signal [thread_id]
		'signal
	construct SignalAll [thread_id]
		'signalAll
	construct Acquire [thread_id]
		'acquire
	construct Release [thread_id]
		'release
	construct CountDown [thread_id]
		'countDown
	construct Submit [thread_id]
		'submit

	replace [program] 
	        P [program]

    by
	P	% Remove all lock method calls
         		[MutateConcurrencyMethod Lock]
		% Remove MUTATED attributes for next pass
		[Clean]

	         	[MutateConcurrencyMethod Unlock]
		% Remove MUTATED attributes for next pass
		[Clean]

         		[MutateConcurrencyMethod Signal]
		% Remove MUTATED attributes for next pass
		[Clean]

	         	[MutateConcurrencyMethod SignalAll]
		% Remove MUTATED attributes for next pass
		[Clean]

	         	[MutateConcurrencyMethod Acquire]
		% Remove MUTATED attributes for next pass
		[Clean]

	         	[MutateConcurrencyMethod Release]
		% Remove MUTATED attributes for next pass
		[Clean]

	         	[MutateConcurrencyMethod CountDown]
		% Remove MUTATED attributes for next pass
		[Clean]

	         	[MutateConcurrencyMethod Submit]
		% Remove MUTATED attributes for next pass
		[Clean]
end function

%------------------------------------------------------------
% Match all method calls with name CurrId
% and then perform the following 3 steps for each:
%	1. Create mutant of program with CurrId removed
%	2. Write mutant to a file
%	3. Reinsert CurrId method call that was removed
%------------------------------------------------------------
rule MutateConcurrencyMethod CurrId [thread_id]
	replace [program]
		P 	[program]

	where
		P 	[?doRemoveConcurrencyMethod CurrId]
	
	by 
		P	% Create the mutant version of the program
			[doRemoveConcurrencyMethod CurrId] 
			%[print] 	
			[writeToFile]
			% Undo mutation and return to original program
			[undoRemoveConcurrencyMethod CurrId]
end rule

%------------------------------------------------------------
% Create a mutant by removing the expression with
% method call CurrId
%------------------------------------------------------------
function doRemoveConcurrencyMethod CurrId [thread_id]
	replace * [expression_statement]
		Expr [expression] '; 

	where
		Expr [hasCurrId CurrId]

	% create mutant comment to appear in source
	construct MutantString [stringlit]
		"RCXC (Remove Concurrency Mechanism Method-X Call)"

	export Expr

	by
		'MUTATED '; /* 'MUTANT: MutantString */
end function

%------------------------------------------------------------
% Reinsert the orginal method call but leave the 
% MUTATED attribute to indicate that the mutant has already
% been created.
%------------------------------------------------------------
function undoRemoveConcurrencyMethod CurrId [thread_id]
	replace * [expression_statement]
		'MUTATED '; /* 'MUTANT: MutantString [stringlit] */

	import Expr [expression]

	by 
		% switch back time but leave hidden attribute
		'MUTATED  Expr ';
end function

%------------------------------------------------------------
% Check if current method is method we are 
% interested in mutating
%------------------------------------------------------------
rule hasCurrId CurrId [thread_id]
	match * [thread_id]
		CurrId
end rule

%------------------------------------------------------------
%Remove MUTATED attributes for next pass
%------------------------------------------------------------
rule Clean
	replace [expression_statement]
		ExprStatement [expression_statement]
	deconstruct ExprStatement
		'MUTATED Expr [expression] ';
	by
		Expr ';
end rule

%Include rules for writing mutants to files
include "WriteMutants.Txl"