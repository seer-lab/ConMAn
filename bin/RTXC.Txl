%***********************************************************
% RTXC (Remove Thread Method-X Call) Mutator
% Jeremy S. Bradbury

% Copyright 2006 J.S. Bradbury

% Revision history:

% Description: Removes a call to the thread methods: wait,
% sleep, join, yield, notify and notifyAll.
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
		'wait
	|	'sleep
	|	'join
	|	'yield
	|	'notify
	|	'notifyAll
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
		"RTXC"
	export MutantOpName

	construct Wait [thread_id]
		'wait
	construct Sleep [thread_id]
		'sleep
	construct Join [thread_id]
		'join
	construct Yield [thread_id]
		'yield
	construct Notify [thread_id]
		'notify
	construct NotifyAll [thread_id]
		'notifyAll

	replace [program] 
        		P [program]

    	by
		P	% Remove all wait method calls
        		 	[MutateThreadMethod Wait]
			% Remove MUTATED attributes for next pass
			[Clean]

         			[MutateThreadMethod Sleep]
			[Clean]

         			[MutateThreadMethod Join]
			[Clean]

		         	[MutateThreadMethod Yield]
			[Clean]

		         	[MutateThreadMethod Notify]
			[Clean]

		         	[MutateThreadMethod NotifyAll]
			[Clean]
end function

%------------------------------------------------------------
% Match all methods calls to CurrId
% and then perform the following 3 steps for each:
%	1. Create mutant of program with CurrId method
% 	call removed.
%	2. Write mutant to a file
%	3. Reinsert CurrId method call that was removed
%------------------------------------------------------------
rule MutateThreadMethod CurrId [thread_id]
	replace [program]
		P 	[program]

	% only proceed for ids that are CurrId
	where
		P 	[?doRemoveThreadMethod CurrId]
	
	by 
		P	% Create the mutant version of the program
			[doRemoveThreadMethod CurrId] 
			%[print] 	
			[writeToFile]
			% Undo mutation and return to original program
			[undoRemoveThreadMethod CurrId]
end rule

%------------------------------------------------------------
% Create a RTXC mutant
%------------------------------------------------------------
function doRemoveThreadMethod CurrId [thread_id]
	replace * [expression_statement]
		Expr [expression] '; 

	where
		Expr [hasCurrId CurrId]

	% create mutant comment to appear in source
	construct MutantString [stringlit]
		"RTXC (Remove Thread Method Call)"

	export Expr

	by
		'MUTATED '; /* 'MUTANT: MutantString */
end function

%------------------------------------------------------------
% Reinsert the orginal method call but leave the 
% MUTATED attribute to indicate that the mutant has already
% been created.
%------------------------------------------------------------
function undoRemoveThreadMethod CurrId [thread_id]
	replace * [expression_statement]
		'MUTATED '; /* 'MUTANT: MutantString [stringlit] */

	import Expr [expression]

	by 
		% switch back time but leave hidden attribute
		'MUTATED  Expr ';
end function

%------------------------------------------------------------
% Check if current method is the one we are currently
% mutating
%------------------------------------------------------------
rule hasCurrId CurrId [thread_id]
	match * [thread_id]
		CurrId
end rule

%-----------------------------------------------------------
% Remove MUTATED attributes for next pass
%-----------------------------------------------------------
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