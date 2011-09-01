%***********************************************************
% MBR (Modify Barrier Runnable Parameter) Mutator
% Jeremy S. Bradbury

% Copyright 2006 J.S. Bradbury

% Description: This mutation operator removes the optional
% runnable parameter from a barrier.
%***********************************************************

% Base grammar, and grammar override files
include "Java.Grm"
include "JavaCommentOverrides.Grm"

% Local grammar overrides

redefine class_instance_creation_expression
		[attr labelM] 'new 'CyclicBarrier '( [argument] [opt second_argument] ')
    |	[attr labelM] 'new 'CyclicBarrier '( [argument] [opt second_argument] ') /* 'MUTANT: [stringlit] */
    |	'new [class_or_interface_name] '( [list argument] ') [opt class_body]
end redefine

define second_argument
	, [argument]
end define

define labelM
	'MUTATED
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
		"MBR"
	export MutantOpName


	replace [program] 
        		P [program]

    	by		% Mutate by removing the runnable parameter
		P 	[MutateBarrierRunnableParam]
end function

%------------------------------------------------------------
% Match all methods with a time parameter 
% and then perform the following 3 steps for each:
%	1. Create mutant of program with Runnable parameter removed
%	2. Write mutant to a file
%	3. Reinsert Barrier's runnable parameter
%------------------------------------------------------------
rule MutateBarrierRunnableParam 
	replace [program]
		P 	[program]

	% only proceed for barrier with runnable parameter
	where
		P 	[?doMutateRunnableParam]
	
	by 
		P	% Create the mutant version of the program
			[doMutateRunnableParam] 
			%[print] 	
			 [writeToFile]
			% Undo mutation and return to original program
			[undoMutateRunnableParam]
end rule

%------------------------------------------------------------
% Create a MBR mutant by removing the runnable
% parameter of a Barrier
%------------------------------------------------------------
function doMutateRunnableParam 
	replace * [class_instance_creation_expression]
		'new 'CyclicBarrier '(  FirstArg [argument] SecondArg [second_argument] ')

	% create mutant comment to appear in source
	construct MutantString [stringlit]
		"MBR (Mutate Barrier Runnable Parameter)"

	export SecondArg

	by
		'MUTATED 'new 'CyclicBarrier '(  FirstArg ')
		/* 'MUTANT: MutantString */
end function

%------------------------------------------------------------
% Reinsert the orginal runnable parameter for a Barrier but
% leave the MUTATED attribute to indicate that the mutant 
% has already been created.
%------------------------------------------------------------
function undoMutateRunnableParam 
	replace * [class_instance_creation_expression]
		'MUTATED 'new 'CyclicBarrier '(  FirstArg [argument] ') 
		/* 'MUTANT: MutantString [stringlit] */

	import SecondArg [second_argument]

	by 
		'MUTATED 'new 'CyclicBarrier '(  FirstArg  SecondArg ')
end function

%Include rules for writing mutants to files
include "WriteMutants.Txl"