%***********************************************************
% MSP (Modify Synchronized Block) Mutator
% Jeremy S. Bradbury

% Copyright 2006 J.S. Bradbury

% Description: This mutation operator modifies the synchronized block
% parameter by replacing it with a parameter from another synchronized
% block.

% Limitations: This mutation operator currently replaces all parameters that
% are not "this" with "this." We will generalize this to replace each parameter
% with every other parameter used in another synchronized block in the same
% class.
%***********************************************************

% Base grammar, and grammar override files
include "Java.Grm"
include "JavaCommentOverrides.Grm"

% Local grammar overrides
redefine synchronized_statement
	[attr labelM]  [synchronized_statement_2]
	| [attr labelM] /* 'MUTANT: [stringlit] */ [NL] [synchronized_statement_2]
end redefine

define synchronized_statement_2
    'synchronized '( [expression] ')
        [statement]                  [NL]
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
		"MSP"
	export MutantOpName

	replace [program] 
        		P [program]

    	by
		% Modify all synchronized block parameters one at 
		% a time
        		P [ModifySynchBlockParameter]
end function

%------------------------------------------------------------
% Match all methods that have a synchronized block 
% and then perform the following 3 steps for each:
%	1. Create mutant of program with synchronized block
%      parameter replaced by another parameter
%	2. Write mutant to a file
%	3. Reinsert original synchronized block parameter that was removed
%------------------------------------------------------------
rule ModifySynchBlockParameter
	replace [program]
		P 	[program]

	% only proceed for methods that satisfy the requirements
	% (i.e. methods that have a synchronized modifier)
	where
		P 	[?doSynchBlockParameterMutation]
	
	by 
		P	% Create the mutant version of the program
			[doSynchBlockParameterMutation] 
			%[print] 	
			[writeToFile]
			% Undo mutation and return to original program
			[undoSynchBlockParameterMutation]
end rule

%------------------------------------------------------------
% Create a MSP mutant by modifying a synchronized
% block parameter
%------------------------------------------------------------
function doSynchBlockParameterMutation
	replace * [synchronized_statement]
		SynchStatement [synchronized_statement]
	
	deconstruct SynchStatement
		SynchStatement2 [synchronized_statement_2]
	deconstruct SynchStatement2
		'synchronized '( Expr [expression] ')
        			Body [statement]

	
	where not Expr [isThis]

	% export the old synchronized expression and reinsert it 
	% once the mutant has been created and saved
	export Expr

	% create mutant comment to appear in source
	construct MutantString [stringlit]
		"MSP (Modify Synchronized Block Parameter)"

	construct ThisExpr [expression]
		'this

	by
		% Replace with empty syncronized statement
		'MUTATED 
		/* 'MUTANT: MutantString */
		'synchronized '( ThisExpr ')
        Body
end function

%------------------------------------------------------------
% Reinsert the orginal method declaration but leave the 
% MUTATED attribute to indicate that the mutant has already
% been created.
%------------------------------------------------------------
function undoSynchBlockParameterMutation
	replace * [synchronized_statement]
		SynchStatement [synchronized_statement]

	% Import the old expression
	import Expr [expression]

	% extract body
	deconstruct SynchStatement
		'MUTATED 
		/* 'MUTANT: MutantString [stringlit] */
		SynchStatement2 [synchronized_statement_2]	
	
	deconstruct SynchStatement2
		'synchronized '( ThisExpr [expression] ')
        			Body [statement]

	by 
		% replace mutated synchronized block with original but 
		% leave hidden attribute
		'MUTATED 
		'synchronized '( Expr ')
		        Body
end function

%------------------------------------------------------------
% Check if current parameter is "this"
%------------------------------------------------------------
rule isThis 
	match [expression]
		'this
end rule

%Include rules for writing mutants to files
include "WriteMutants.Txl"
