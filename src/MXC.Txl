%***********************************************************
% MXC (Modify Method-X Count) Mutator
% Jeremy S. Bradbury, Oct. 7, 2006

% Copyright 2006 J.S. Bradbury

% Description: This mutation operator modifies the permit
% count in Semaphores and the thread counts in Latches and
% Barriers. The count is decremented or incremented by 1.

% Limitations:
% This mutator only modifies the time in instances of
% CountDownLatch, Semaphore, and CyclicBarrier, classes that
% extend these are not modified and should be included or we
% should included modifications to super() from the constructor
% of classes that extended these.
%***********************************************************

% Base grammar, and grammar override files
include "Java.Grm"
include "JavaCommentOverrides.Grm"

% Local grammar overrides
redefine class_instance_creation_expression
	[attr labelM] 'new [count_class_name] '( [additive_expression] [rest_of_creation_expression] 
    |	[attr labelM] 'new [count_class_name] '( [additive_expression] [rest_of_creation_expression] /* 'MUTANT: [stringlit] */
    |	'new [class_or_interface_name] '( [list argument] ') [opt class_body]
end redefine

define rest_of_creation_expression
		')
	|	', [list argument] ')
end define

define count_class_name
		'CountDownLatch
	|	'Semaphore
	|	'CyclicBarrier
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

	% initialize and export the name of the current mutant while 
	% will be used for folder name generation
	construct MutantOpName [stringlit]
		"MXC"
	export MutantOpName

	% set the count factor to decrement and increment by
	construct CountFactor [number]
		1
	export CountFactor

	construct Sem [count_class_name]
		'Semaphore
	construct Latch [count_class_name]
		'CountDownLatch
	construct Barrier [count_class_name]
		'CyclicBarrier

	construct Add [add_op]
		+
	construct Subtract [add_op]
		-

	replace [program] 
        		P [program]

    	by		% Replace all count parameters by (count + factor)
        		P 	[MutateMethodCount Add Sem]
			% Remove MUTATED attributes for next pass
			[Clean Sem]
			% Replace all count parameters by (count - factor)
        			[MutateMethodCount Subtract Sem]
			[Clean Sem]

			[MutateMethodCount Add Latch]
			[Clean Latch]
        			[MutateMethodCount Subtract Latch]
			[Clean Latch]

			[MutateMethodCount Add Barrier]
			[Clean Barrier]
        			[MutateMethodCount Subtract Barrier]
end function

%------------------------------------------------------------
% Match all methods with a count parameter 
% and then perform the following 3 steps for each:
%	1. Create mutant of program with count changed
%	2. Write mutant to a file
%	3. Reinsert original count that was removed
%------------------------------------------------------------
rule MutateMethodCount CurrOp [add_op] CurrClass [count_class_name]
	replace [program]
		P 	[program]

	% only proceed for semaphore, latch, or barrier constructors
	where
		P 	[?doMutateCount CurrOp CurrClass]
	
	by 
		P	% Create the mutant version of the program
			[doMutateCount CurrOp CurrClass] 
			%[print] 	
			 [writeToFile]
			% Undo mutation and return to original program
			[undoMutateCount CurrOp CurrClass]
end rule

%------------------------------------------------------------
% Create a MXC mutant by incrementing or decrementing the
% count parameter
%------------------------------------------------------------
function doMutateCount CurrOp [add_op] CurrClass [count_class_name]
	replace * [class_instance_creation_expression]
		'new CountClass [count_class_name] '( FirstArg [additive_expression] 
		Rest [rest_of_creation_expression]
		
	where
		CountClass [isCurrClass CurrClass]

	% create mutant comment to appear in source
	construct MutantString [stringlit]
		"MXC (Mutate Method-X Count)"

	export FirstArg

	import CountFactor [number]
	
	construct NewFirstArg [additive_expression]
		'( FirstArg ') CurrOp CountFactor

	by
		'MUTATED 'new CountClass '( NewFirstArg Rest
		/* 'MUTANT: MutantString */
end function

%------------------------------------------------------------
% Reinsert the orginal count but leave the 
% MUTATED attribute to indicate that the mutant'
% has already been created.
%------------------------------------------------------------
function undoMutateCount CurrOp [add_op] CurrClass [count_class_name]
	replace * [class_instance_creation_expression]
		'MUTATED 'new CountClass [count_class_name] 
		'( NewFirstArg [additive_expression]  
		Rest [rest_of_creation_expression] 
		/* 'MUTANT: MutantString [stringlit] */

	import FirstArg [additive_expression]

	by	% switch back count but leave hidden attribute
		'MUTATED 'new  CountClass '( FirstArg Rest 
end function

%------------------------------------------------------------
% Check if current class type is current type we are 
% interested in
%------------------------------------------------------------
rule isCurrClass CurrClass [count_class_name]
	match [count_class_name]
		CurrClass
end rule

%------------------------------------------------------------
% Remove MUTATED attributes for next pass
%------------------------------------------------------------
rule Clean CurrClass [count_class_name]
	replace [class_instance_creation_expression]
		CreateExpr [class_instance_creation_expression]
	deconstruct CreateExpr
		'MUTATED 'new  CurrClass '( FirstArg [additive_expression] 
		Rest [rest_of_creation_expression]
	by
		'new  CurrClass '( FirstArg Rest
end rule

%Include rules for writing mutants to files
include "WriteMutants.Txl"