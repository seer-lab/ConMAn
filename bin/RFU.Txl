%***********************************************************
% RFU (Remove Finally around Unlock) Mutator
% Jeremy S. Bradbury

% Copyright 2006 J.S. Bradbury

% Description: This mutation operator removes the 
% the finally around a block that contains an unlock.
% The finally block ensures that an unlock will occur
% regardless if the try block before it throws an exception
%***********************************************************

% Base grammar, and grammar override files
include "Java.Grm"
include "JavaCommentOverrides.Grm"

% Local grammar overrides
define labelM
	'MUTATED
end define

redefine try_statement
	[try_with_finally]
	| [try_without_finally]
end redefine

define try_with_finally
     	[attr labelM]  'try [block] [repeat catch_clause] [finally_clause]    [NL]
     	| [attr labelM]  'try [block] [repeat catch_clause] [block]  /* 'MUTANT: [stringlit] */  [NL]
end define

define try_without_finally
	'try [block] [repeat catch_clause]    [NL]
end define

%define finally_clause
%    'finally [block] 
%end define

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
		"RFU"
	export MutantOpName

	replace [program] 
        		P [program]

    	by
		% Remove finally around a block of statements that 
		% contains an unlock
        		P [MutateFinallyDel]
end function

%------------------------------------------------------------
% Match all try_statements that have an optionally finally clause
% with an unlock statement and then perform the following 3 steps
% for each:
%	1. Create mutant of program with Finally removed around block
%      removed
%	2. Write mutant to a file
%	3. Reinsert Finally that was removed
%------------------------------------------------------------
rule MutateFinallyDel
	replace [program]
		P 	[program]

	% only proceed for try_statements that satisfy the requirements
	% (i.e. unlock inside finally clause)
	where
		P 	[?doFinallyDelMutation]

	by 
		P	
			% Create the mutant version of the program
			[doFinallyDelMutation] 
			%[print] 	
			 [writeToFile]
			% Undo mutation and return to original program
			[undoFinallyDelMutation]
end rule

%------------------------------------------------------------
% Create an RVK mutant by removing Finally from the 
% method modifier list
%------------------------------------------------------------
function doFinallyDelMutation
	replace * [try_with_finally]
     		'try TBlock [block] CClause [repeat catch_clause] FClause [finally_clause]  

	deconstruct FClause
		'finally FBlock [block]

	% check that Finally modifier is present
	where
		FBlock [hasUnlock]

	% create mutant comment to appear in source
	construct MutantString [stringlit]
		"RFU (Removed Finally Around Unlock)"

	by
		% generate hidden attribute
		'MUTATED 
		% create new try block without finally
		'try TBlock CClause FBlock  
		% generate comment
		/* 'MUTANT: MutantString */ 
end function

%------------------------------------------------------------
% Reinsert the finally block but leave the 
% MUTATED attribute to indicate that the mutant has already
% been created.
%------------------------------------------------------------
function undoFinallyDelMutation
	replace * [try_with_finally]
		'MUTATED 'try TBlock [block] CClause [repeat catch_clause] FBlock [block] 	
		/* 'MUTANT: MutantString [stringlit] */
		  
	construct FClause [finally_clause]
		'finally FBlock	

	by 
		% replace mutated code with original
		% leave hidden attribute
		'MUTATED 'try TBlock CClause FClause
end function

%------------------------------------------------------------
% Check if finally block has unlock
%------------------------------------------------------------
rule hasUnlock
	match * [dot_id]
		'. 'unlock
end rule

%Include rules for writing mutants to files
include "WriteMutants.Txl"