%***********************************************************
% MSF (Modify Semaphore Faireness) Mutator
% Jeremy S. Bradbury

% Copyright 2006 J.S. Bradbury

% Description: This mutation operator modifies the optional
% fairness parameter of a Semaphores by negating it.
%***********************************************************

% Base grammar, and grammar override files
include "Java.Grm"
include "JavaCommentOverrides.Grm"

% Local grammar overrides

redefine class_instance_creation_expression
		[attr labelM] 'new 'Semaphore '( [argument] , [argument] ')
    |	[attr labelM] 'new 'Semaphore '( [argument] , [argument] ') /* 'MUTANT: [stringlit] */
    |	'new [class_or_interface_name] '( [list argument] ') [opt class_body]
end redefine

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
		"MSF"
	export MutantOpName

	replace [program] 
        		P [program]

    	by
			% Negate semaphore fairness parameter
        		P 	[MutateSemaphoreFairness]
			
end function

%------------------------------------------------------------
% Match all methods with a time parameter 
% and then perform the following 3 steps for each:
%	1. Create mutant of program with negated Semaphore fairness
%	2. Write mutant to a file
%	3. Reset the fairness parameter
%------------------------------------------------------------
rule MutateSemaphoreFairness 
	replace [program]
		P 	[program]

	% only proceed for semaphore with fairness parameter
	where
		P 	[?doMutateFairness]
	
	by 
		P	% Create the mutant version of the program
			[doMutateFairness] 
			%[print] 	
			 [writeToFile]
			% Undo mutation and return to original program
			[undoMutateFairness]
end rule

%------------------------------------------------------------
% Create a MSF mutant by negativing the fairness parameter
% of a Semaphore
%------------------------------------------------------------
function doMutateFairness 
	replace * [class_instance_creation_expression]
		'new 'Semaphore '(  FirstArg [argument] , SecondArg [argument] ')

	% create mutant comment to appear in source
	construct MutantString [stringlit]
		"MSF (Mutate Semaphore Fairness)"

	export SecondArg

	deconstruct SecondArg
		SecondExpr [expression]

	construct NewSecondArg [argument]
		! '( SecondExpr ') 

	by
		'MUTATED 'new 'Semaphore '(  FirstArg  , 
		NewSecondArg ')
		/* 'MUTANT: MutantString */
end function

%------------------------------------------------------------
% Reinsert the orginal fairness parameter for a Semaphore but
% leave the MUTATED attribute to indicate that the mutant 
% has already been created.
%------------------------------------------------------------
function undoMutateFairness 
	replace * [class_instance_creation_expression]
		'MUTATED 'new 'Semaphore '(  FirstArg [argument] , 
		NewSecondArg [argument] ') 
		/* 'MUTANT: MutantString [stringlit] */

	import SecondArg [argument]

	by 
		% switch back count but leave hidden attribute
		'MUTATED 'new 'Semaphore '(  FirstArg  , SecondArg ')
end function

%Include rules for writing mutants to files
include "WriteMutants.Txl"