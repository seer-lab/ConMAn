%***********************************************************
% MXT (Modify Method-X Time) Mutator
% Jeremy S. Bradbury

% Copyright 2006 J.S. Bradbury

% Description: This mutation operator modifies the time in
% method calls to wait, sleep, join, and await by both 
% increasing and decreasing the amount of time

%Limitations: 
% In all methods we only mutate the first optional time
% parameter. Each of these methods also has a second optional
% parameter. The wait, sleep, join methods have a nanosecond
% time amount and the await method has a timeunits parameter.

%The tryAcquire and tryLock methods which have optional 
% timeouts and we currently do not modify the time in these methods.
%***********************************************************

% Base grammar, and grammar override files
include "Java.Grm"
include "JavaCommentOverrides.Grm"

% Local grammar overrides

redefine reference
		[time_part]
	|	[id] '. [time_part]
    | 	[id] [repeat component]
end redefine

define time_part
		[attr labelM] [time_method] '(  [list additive_expression] ')
	| 	[attr labelM] [time_method] '( [list additive_expression] ') /* 'MUTANT: [stringlit] */
end define

define time_method
		'wait
	|	'sleep
	|	'join
	|	'await
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
		"MXT"
	export MutantOpName

	% set the factor of time to decrement and increment by
	construct TimeFactor [number]
		2
	export TimeFactor

	construct Wait [time_method]
		'wait
	construct Sleep [time_method]
		'sleep
	construct Join [time_method]
		'join
	construct Await [time_method]
		'await

	construct Mult [mult_op]
		*
	construct Div [mult_op]
		/

	replace [program] 
        P [program]

    by		% Replace all time parameters by time * factor
        		P 	[MutateMethodTime Mult Wait]
		% Remove MUTATED attributes for next pass
			[Clean Wait]
		% Replace all time parameters by time / factor
        			[MutateMethodTime Div Wait]
			[Clean Wait]

			[MutateMethodTime Mult Sleep]
			[Clean Sleep]
        			[MutateMethodTime Div Sleep]
			[Clean Sleep]

			[MutateMethodTime Mult Join]
			[Clean Join]
        			[MutateMethodTime Div Join]
			[Clean Join]

			[MutateMethodTime Mult Await]
			[Clean Await]
        			[MutateMethodTime Div Await]
end function

%------------------------------------------------------------
% Match all methods with a time parameter 
% and then perform the following 3 steps for each:
%	1. Create mutant of program with time
% 	increased or decreased.
%	2. Write mutant to a file
%	3. Switch back to original time
%------------------------------------------------------------
rule MutateMethodTime CurrOp [mult_op] CurrMethod [time_method]
	replace [program]
		P 	[program]

	where
		P 	[?doMutateTime CurrOp CurrMethod]
	
	by 
		P	% Create the mutant version of the program
			[doMutateTime CurrOp CurrMethod] 
			%[print] 	
			[writeToFile]
			% Undo mutation and return to original program
			[undoMutateTime CurrOp CurrMethod]
end rule

%------------------------------------------------------------
% Create a MXT mutant by increasing or decreasing the
% time parameter
%------------------------------------------------------------
function doMutateTime CurrOp [mult_op] CurrMethod [time_method]
	replace * [time_part]
		TimeMethod [time_method] 
		'( AddExpr [list additive_expression] ')

	where
		TimeMethod [isCurrMethod CurrMethod]

	% create mutant comment to appear in source
	construct MutantString [stringlit]
		"MXT (Mutate Method-X Time)"

	export AddExpr

	deconstruct AddExpr
		FirstExpr [additive_expression] , RestExpr [list additive_expression]
	
	import TimeFactor [number]

	by	% Replace with sleep method call
		'MUTATED TimeMethod '( '( FirstExpr ') CurrOp TimeFactor, RestExpr 
		') /* 'MUTANT: MutantString */
end function

%------------------------------------------------------------
% Reinsert the orginal time but leave the 
% MUTATED attribute to indicate that the 
% mutant has already been created.
%------------------------------------------------------------
function undoMutateTime CurrOp [mult_op] CurrMethod [time_method]
	replace * [time_part]
		'MUTATED TimeMethod [time_method]
		'( CurrAddExpr [list additive_expression] ') 
		/* 'MUTANT: MutantString [stringlit] */

	import AddExpr [list additive_expression]

	by 
		% switch back time but leave hidden attribute
		'MUTATED  CurrMethod '( AddExpr ') 
end function

%------------------------------------------------------------
% Check if current method is the time method we are 
% interested in
%------------------------------------------------------------
rule isCurrMethod CurrMethod [time_method]
	match [time_method]
		CurrMethod
end rule

%------------------------------------------------------------
%Remove MUTATED attributes for next pass
%------------------------------------------------------------
rule Clean CurrMethod [time_method]
	replace [time_part]
		Ref [time_part]
	deconstruct Ref
		'MUTATED CurrMethod '( AddExpr [list additive_expression] ')
	by
		CurrMethod '( AddExpr ')
end rule

%Include rules for writing mutants to files
include "WriteMutants.Txl"